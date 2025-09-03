// lib/screens/InventoryScreen.dart
import 'package:flutter/material.dart';
import 'package:quickbill/api/API.dart';
import 'package:quickbill/models/Product.dart';
import 'package:quickbill/widgets/ProductCard.dart';
import 'package:quickbill/widgets/ProductForm.dart';
import 'package:quickbill/constants/colors.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Product> _products = [];
  bool _isLoading = true;
  bool _showForm = false;
  Product? _editingProduct;
  final ScrollController _scrollController = ScrollController();
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  List<Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((product) {
        return product.name.toLowerCase().contains(query) ||
            product.barcode.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final response = await apiServices.getProducts();
    if (response.success) {
      setState(() {
        _products = response.data as List<Product>;
        _filteredProducts = _products;
        _isLoading = false;
      });
    } else {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text(response.message ?? 'Failed to load products')),
      // );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSubmit(Map<String, dynamic> formData) async {
    setState(() => _isLoading = true);

    final productData = {
      'name': formData['name'],
      'barcode': formData['barcode'],
      'description': formData['description'],
      'price': formData['price'],
      'stock': formData['stock'],
      // Add GST fields if they exist in formData
      if (formData['gst_rate'] != null) 'gst_rate': formData['gst_rate'],
      if (formData['cgst'] != null) 'cgst': formData['cgst'],
      if (formData['sgst'] != null) 'sgst': formData['sgst'],
      if (formData['igst'] != null) 'igst': formData['igst'],
      if (formData['cess'] != null) 'cess': formData['cess'],
    };

    try {
      if (_editingProduct == null) {
        final response = await apiServices.createProduct(productData);
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product created successfully')),
          );
        } else {
          throw response.message ?? 'Failed to create product';
        }
      } else {
        final response = await apiServices.updateProduct(
            _editingProduct!.id, productData);
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully')),
          );
        } else {
          throw response.message ?? 'Failed to update product';
        }
      }
      await _loadProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString() ) ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _showForm = false;
        _editingProduct = null;
      });
    }
  }

  Future<void> _deleteProduct(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final response = await apiServices.deleteProduct(id);
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
        await _loadProducts();
      } else {
        throw response.message ?? 'Failed to delete product';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _editProduct(Product product) {
    setState(() {
      _editingProduct = product;
      _showForm = true;
    });
  }

  PreferredSizeWidget _buildAppBar() {
    if (_showSearch) {
      return AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search products...',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _showSearch = false;
                  _searchController.clear();
                });
              },
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _showSearch = false;
              _searchController.clear();
            });
          },
        ),
      );
    }

    return AppBar(
      title: const Text('Inventory'),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            setState(() => _showSearch = true);
          },
        ),
        if (!_showForm && _products.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filter functionality coming soon')),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No Products Found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add your first product to get started',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Product'  ),
            onPressed: () {
              setState(() {
                _showForm = true;
                _editingProduct = null;
              });
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          return ProductCard(
            product: product,
            onEdit: () => _editProduct(product),
            onDelete: () => _deleteProduct(product.id),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _showForm
          ? ProductForm(
        product: _editingProduct,
        onSubmit: _handleSubmit,
        onCancel: () {
          setState(() {
            _showForm = false;
            _editingProduct = null;
          });
        },
      )
          : _filteredProducts.isEmpty
          ? _buildEmptyState()
          : _buildProductList(),
      floatingActionButton: !_showForm && !_showSearch
          ? FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _showForm = true;
            _editingProduct = null;
          });
        },
        icon: const Icon(Icons.add , color: Colors.white ),
        label: const Text('Add Product' ,style: TextStyle(color: Colors.white), ),
        backgroundColor: AppColors.primaryColor,
        elevation: 4,
      )
          : null,
    );
  }
}