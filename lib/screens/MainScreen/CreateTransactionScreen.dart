import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:quickbill/api/API.dart';
import 'package:quickbill/models/CartItem.dart';
import 'package:quickbill/models/Product.dart';
import 'package:quickbill/constants/colors.dart';
import 'package:lottie/lottie.dart';
import '../../models/Customer.dart';
import 'InventoryScreen.dart';
import 'TransactionConfirmationScreen.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

class CreateTransactionScreen extends StatefulWidget {
  const CreateTransactionScreen({Key? key}) : super(key: key);

  @override
  _CreateTransactionScreenState createState() => _CreateTransactionScreenState();
}

class _CreateTransactionScreenState extends State<CreateTransactionScreen> {

  final MobileScannerController _scannerController = MobileScannerController();
  List<CartItem> _cartItems = [];
  double _totalAmount = 0.0;
  double _discount = 0.0;
  double _finalAmount = 0.0;
  String _paymentMode = 'cash';
  bool _isLoading = false;
  bool _showScanner = false;
  bool _showSuccessAnimation = false;
  final TextEditingController _discountController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  TextEditingController _mobileController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  Customer? _selectedCustomer;
  bool _isSearchingCustomer = false;
  bool _showCustomerForm = false;
  List<Customer> _searchResults = [];
  Map<String, bool> _updatingItems = {};

  bool _isCustomerValid() {
    // Either a customer is selected OR mobile number is entered (for new customer)
    return _selectedCustomer != null ||
        (_mobileController.text.isNotEmpty && _mobileController.text.length >= 10);
  }

  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<String> _paymentModes = ['cash', 'card', 'upi', 'wallet'];

  @override
  void initState() {
    super.initState();
    _loadCart();
    _discountController.addListener(_updateDiscount);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _discountController.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _searchCustomers() async {
    final query = _mobileController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearchingCustomer = true);
    try {
      final response = await apiServices.searchCustomers(query);
      if (response.success) {
        setState(() {
          _searchResults = response.data ?? [];
          _showCustomerForm = _searchResults.isEmpty;
        });
      } else {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text(response.message ?? 'Search failed')),
        // );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search error: $e')),
      );
    } finally {
      setState(() => _isSearchingCustomer = false);
    }
  }

  Future<void> _createCustomer() async {
    final name = _nameController.text.trim();
    final mobile = _mobileController.text.trim();
    if (name.isEmpty || mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter name and mobile number')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await apiServices.createCustomer(
        name: name,
        mobile: mobile,
      );
      if (response.success && response.data != null) {
        setState(() {
          _selectedCustomer = response.data;
          _showCustomerForm = false;
        });
      } else {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text(response.message ?? 'Failed to create customer')),
        // );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating customer: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearCustomer() {
    setState(() {
      _selectedCustomer = null;
      _mobileController.clear();
      _nameController.clear();
      _searchResults.clear();
      _showCustomerForm = false;
    });
  }

  void _updateDiscount() {
    final discount = double.tryParse(_discountController.text) ?? 0;
    setState(() {
      _discount = discount;
      _calculateTotals();
    });
  }

  // Update the customer search UI in _buildCustomerSection:
  Widget _buildCustomerSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Customer Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (_selectedCustomer != null) ...[
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, size: 20),
                    onPressed: _clearCustomer,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            if (_selectedCustomer != null) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                  child: Icon(Icons.person, color: AppColors.primaryColor),
                ),
                title: Text(
                  _selectedCustomer?.name ?? 'No Name', // Add null check
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(_selectedCustomer?.mobile ?? 'No Mobile'), // Add null check
              ),
            ] else ...[
              TextField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  hintText: 'Enter customer mobile number',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  suffixIcon: _isSearchingCustomer
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : IconButton(
                    icon: Icon(Icons.search),
                    onPressed: _searchCustomers,
                  ),
                ),
                onSubmitted: (_) => _searchCustomers(),
              ),

              if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: 12),
                ..._searchResults.map((customer) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    child: Icon(Icons.person_outline, color: Colors.grey.shade600),
                  ),
                  title: Text(customer.name),
                  subtitle: Text(customer.mobile),
                  trailing: Text('₹${customer.totalSpent.toStringAsFixed(2)}'),
                  onTap: () {
                    setState(() {
                      _selectedCustomer = customer;
                      _searchResults.clear();
                    });
                  },
                )).toList(),
              ],

              if (_showCustomerForm) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Customer Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _createCustomer,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                    backgroundColor: AppColors.primaryColor,
                  ),
                  child: _isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                      : Text('Add New Customer', style: TextStyle(color: Colors.white)),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

// Update the _generateBill method to immediately clear local cart:
  Future<void> _generateBill() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }

    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransactionConfirmationScreen(
            cartItems: _cartItems,
            totalAmount: _totalAmount,
            discount: _discount,
            finalAmount: _finalAmount,
            paymentMode: _paymentMode,
            customer: _selectedCustomer,
          ),
        ),
      );

      if (result == true) {
        // Immediately clear local cart for better UX
        setState(() {
          _cartItems.clear();
          _clearCustomer();
          _totalAmount = 0;
          _discount = 0;
          _finalAmount = 0;
          _discountController.clear();
        });

        // Show success animation
        setState(() => _showSuccessAnimation = true);
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          // _clearCustomer();
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Future<void> _loadCart() async {
  //   setState(() => _isLoading = true);
  //   try {
  //     final response = await apiServices.getCart();
  //     if (response.success) {
  //       setState(() {
  //         _cartItems = response.data ?? [];
  //         _calculateTotals();
  //       });
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text(response.message ?? 'Failed to load cart')),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to load cart: $e')),
  //     );
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);
    try {
      final response = await apiServices.getCart();
      if (response.success) {
        setState(() {
          _cartItems = response.data ?? []; // Ensure we don't get null
          _calculateTotals();
        });
      } else {
        if (mounted) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text(response.message ?? 'Failed to load cart')),
          // );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load cart: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateTotals() {
    final total = _cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    final finalAmount = total - _discount;

    setState(() {
      _totalAmount = total;
      _finalAmount = finalAmount > 0 ? finalAmount : 0;
    });
  }

  Future<void> _scanBarcode() async {
    setState(() => _showScanner = true);
  }

  // Future<void> _handleBarcode(Barcode barcode) async {
  //   if (!_showScanner) return;
  //
  //   await _playScanEffects();
  //
  //   setState(() => _showScanner = false);
  //
  //   final String? barcodeValue = barcode.rawValue;
  //   if (barcodeValue == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Failed to scan barcode')),
  //     );
  //     return;
  //   }
  //
  //   setState(() => _isLoading = true);
  //   try {
  //     final response = await apiServices.getProductByBarcode(barcodeValue);
  //     if (response.success && response.data != null) {
  //       await _addToCart(response.data!);
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text(response.message ?? 'Product not found')),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error: $e')),
  //     );
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }


  Future<void> _handleBarcode(Barcode barcode) async {
    if (!_showScanner) return;

    await _playScanEffects();

    setState(() => _showScanner = false);

    final String? barcodeValue = barcode.rawValue;
    if (barcodeValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to scan barcode')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await apiServices.getProductByBarcode(barcodeValue);
      if (response.success && response.data != null) {
        await _addToCart(response.data!);
      } else {
        // Show product not found dialog
        await _showProductNotFoundDialog(barcodeValue);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<void> _showProductNotFoundDialog(String barcode) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Product Not Found'),
        content: Text('No product found with barcode: $barcode'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          // TextButton(
          //   onPressed: () => Navigator.pop(context, true),
          //   child: const Text('Add Product'),
          // ),
        ],
      ),
    );

    // if (result == true) {
    //   // Navigate to InventoryScreen with barcode pre-filled
    //   if (mounted) {
    //     await Navigator.push(
    //       context,
    //       MaterialPageRoute(
    //         builder: (context) => InventoryScreen(
    //           initialBarcode: barcode,
    //         ),
    //       ),
    //     );
    //   }
    // }
  }

  Future<void> _playScanEffects() async {
    try {
      // Vibrate for 200ms
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 200);
      }

      // Play beep sound
      await _audioPlayer.play(AssetSource('audio/beep.mp3'));

    } catch (e) {
      debugPrint('Error playing scan effects: $e');
    }
  }

  Future<void> _addToCart(Product product) async {
    try {
      // Check if product already exists in cart
      final existingItem = _cartItems.firstWhere(
            (item) => item.productId == product.id,
        orElse: () => CartItem.empty(),
      );

      if (existingItem.productId.isNotEmpty) {
        // If exists, increment quantity locally first for better UX
        setState(() {
          _cartItems = _cartItems.map((item) {
            if (item.productId == product.id) {
              return item.copyWith(quantity: item.quantity + 1);
            }
            return item;
          }).toList();
          _calculateTotals();
        });
      }

      await apiServices.addToCart(product.id);
      await _loadCart();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add to cart: $e')),
      );
      // Revert local changes if API call fails
      await _loadCart();
    }
  }

  Future<void> _removeFromCart(String productId) async {
    try {
      setState(() {
        _updatingItems[productId] = true;
        _cartItems.removeWhere((item) => item.productId == productId);
        _calculateTotals();
      });

      await apiServices.removeFromCart(productId);
      await _loadCart();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove from cart: $e')),
      );
      await _loadCart();
    } finally {
      setState(() {
        _updatingItems.remove(productId);
      });
    }
  }

  Future<void> _updateQuantity(String productId, int newQuantity) async {
    if (newQuantity < 1) {
      await _removeFromCart(productId);
      return;
    }

    try {
      setState(() {
        _updatingItems[productId] = true;
        _cartItems = _cartItems.map((item) {
          if (item.productId == productId) {
            return item.copyWith(quantity: newQuantity);
          }
          return item;
        }).toList();
        _calculateTotals();
      });

      // Since we don't have an update API, we'll remove and add again
      await apiServices.removeFromCart(productId);
      await apiServices.addToCart(productId, newQuantity);
      await _loadCart();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update quantity: $e')),
      );
      await _loadCart();
    } finally {
      setState(() {
        _updatingItems.remove(productId);
      });
    }
  }

  Future<void> _clearCart() async {
    try {
      setState(() => _isLoading = true);
      await apiServices.clearCart();
      await _loadCart();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear cart: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /*Future<void> _generateBill() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }

    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransactionConfirmationScreen(
            cartItems: _cartItems,
            totalAmount: _totalAmount,
            discount: _discount,
            finalAmount: _finalAmount,
            paymentMode: _paymentMode,
            customer: _selectedCustomer,
          ),
        ),
      );

      if (result == true) {
           _clearCart();
        _clearCustomer();
        setState(() => _showSuccessAnimation = true);

        // Wait for animation to complete
        await Future.delayed(const Duration(seconds: 2));

        // Clear data only if widget is still mounted
        if (mounted) {
          // Navigate back only once
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }*/

  Widget _buildScannerOverlay() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (barcode) => _handleBarcode(barcode.barcodes.first),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10, // Account for status bar
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => setState(() => _showScanner = false),
            ),
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20, // Account for bottom padding
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Scan a product barcode',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  onPressed: () => _scannerController.toggleTorch(),
                  child: Icon(
                    _scannerController.torchEnabled
                        ? Icons.flash_on
                        : Icons.flash_off,
                    color: Colors.black,
                  ),
                  backgroundColor: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    final isUpdating = _updatingItems[item.productId] ?? false;

    return Dismissible(
      key: Key(item.productId),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove Item'),
            content: Text('Remove ${item.name} from cart?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => _removeFromCart(item.productId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Product Image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      image: item.imageUrl != null
                          ? DecorationImage(
                        image: NetworkImage(item.imageUrl!),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: item.imageUrl == null
                        ? Icon(Icons.shopping_bag, color: Colors.grey.shade400)
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Product Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name ?? 'Unnamed Product', // Add null check
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${item.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quantity Controls
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18),
                          onPressed: isUpdating
                              ? null
                              : () => _updateQuantity(
                            item.productId,
                            item.quantity - 1,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: isUpdating
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : Text(
                            item.quantity.toString(),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          onPressed: isUpdating
                              ? null
                              : () => _updateQuantity(
                            item.productId,
                            item.quantity + 1,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isUpdating)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Subtotal
            _buildAmountRow('Subtotal', _totalAmount),
            const SizedBox(height: 12),

            // Discount
            Row(
              children: [
                const Text('Discount', style: TextStyle(fontSize: 16)),
                const Spacer(),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: '₹',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      isDense: true,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Divider
            Container(
              height: 1,
              color: Colors.grey.shade200,
              margin: const EdgeInsets.symmetric(vertical: 8),
            ),

            // Final Amount
            _buildAmountRow('Total Amount', _finalAmount, isBold: true),
            const SizedBox(height: 16),

            // Payment Mode
            DropdownButtonFormField<String>(
              value: _paymentMode,
              items: _paymentModes.map((mode) {
                return DropdownMenuItem<String>(
                  value: mode,
                  child: Text(
                    mode.toUpperCase(),
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _paymentMode = value);
                }
              },
              decoration: InputDecoration(
                labelText: 'Payment Mode',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                isDense: true,
              ),
              isExpanded: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          const Spacer(),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppColors.primaryColor : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showScanner) {
      return _buildScannerOverlay();
    }

/*    if (_showSuccessAnimation) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
              Lottie.asset(
                'lib/assets/LottieFies/successfull.json',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              const Text(
                'Bill Generated Successfully!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      );
    }*/

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Bill'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _cartItems.isEmpty ? null : _clearCart,
            tooltip: 'Clear Cart',
          ),
        ],
      ),
      body: _isLoading && _cartItems.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Scan Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_scanner, size: 24),
                label: const Text(
                  'SCAN PRODUCT',
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: _scanBarcode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ),

          // Main scrollable content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadCart,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildCustomerSection(),

                    if (_cartItems.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 100),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 80,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Your cart is empty',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Scan a product to get started',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_cartItems.isNotEmpty) ...[
                      ..._cartItems.map((item) => _buildCartItem(item)).toList(),
                      _buildSummaryCard(),
                      const SizedBox(height: 80), // Space for the bottom button
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _cartItems.isEmpty
          ? null
          : Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,

            child: ElevatedButton.icon(
              onPressed: _isCustomerValid() ? _generateBill : null,
              icon: const Icon(Icons.receipt_long),
              label: const Text(
                'Create a Transaction',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isCustomerValid()
                    ? AppColors.primaryColor
                    : AppColors.primaryColor.withOpacity(0.5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}