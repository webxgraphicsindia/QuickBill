import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:quickbill/models/CartItem.dart';
import 'package:quickbill/constants/colors.dart';
import 'package:quickbill/api/API.dart';
import 'package:lottie/lottie.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/Customer.dart';
import '../../models/User.dart';
import '../../utils/TaxSettings.dart';

class TransactionConfirmationScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final double totalAmount;
  final double discount;
  final double finalAmount;
  final String paymentMode;
  final Customer? customer;
  const TransactionConfirmationScreen({
    Key? key,
    required this.cartItems,
    required this.totalAmount,
    required this.discount,
    required this.finalAmount,
    required this.paymentMode,
    this.customer,
  }) : super(key: key);

  @override
  _TransactionConfirmationScreenState createState() => _TransactionConfirmationScreenState();
}

class _TransactionConfirmationScreenState extends State<TransactionConfirmationScreen> {
  bool _isProcessing = false;
  bool _showSuccess = false;
  User? _user;
  bool _isLoading = true;
  bool _taxBillingEnabled = false;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTaxSetting();
  }

  Future<void> _loadTaxSetting() async {
    _taxBillingEnabled = await TaxSettings.isTaxBillingEnabled();
    setState(() {});
  }

  Future<void> _loadUserData() async {
    try {
      final userJson = await _storage.read(key: 'user_details');
      if (userJson != null) {
        setState(() {
          _user = User.fromJson(jsonDecode(userJson));
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processTransaction() async {
    if (!mounted) return;

    setState(() => _isProcessing = true);

    try {
      final items = widget.cartItems.map((item) => item.toJson()).toList();
      final response = await apiServices.createTransaction(
        items: items,
        totalAmount: widget.totalAmount,
        discount: widget.discount,
        finalAmount: widget.finalAmount,
        paymentMode: widget.paymentMode,
        customerId: widget.customer?.id,
        customerMobile: widget.customer?.mobile ?? '',
      );

      if (response.success) {
        await apiServices.clearCart();
        setState(() => _showSuccess = true);
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? 'Transaction failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted && !_showSuccess) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Widget _buildTaxRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const Spacer(),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePdfBill() async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load('lib/assets/fonts/arial.TTF');
    final ttf = pw.Font.ttf(fontData);

    final logo = pw.MemoryImage(
      (await rootBundle.load('lib/assets/images/Billlogo.png')).buffer.asUint8List(),
    );

    final now = DateTime.now();

    // Calculate taxes if enabled
    double totalCgst = 0;
    double totalSgst = 0;
    double totalIgst = 0;
    double totalCess = 0;
    double totalTax = 0;

    if (_taxBillingEnabled) {
      totalCgst = widget.cartItems.fold(0.0, (sum, item) => sum + (item.cgst ?? 0) * item.quantity);
      totalSgst = widget.cartItems.fold(0.0, (sum, item) => sum + (item.sgst ?? 0) * item.quantity);
      totalIgst = widget.cartItems.fold(0.0, (sum, item) => sum + (item.igst ?? 0) * item.quantity);
      totalCess = widget.cartItems.fold(0.0, (sum, item) => sum + (item.cess ?? 0) * item.quantity);
      totalTax = totalCgst + totalSgst + totalIgst + totalCess;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.SizedBox(width: 80, height: 80, child: pw.Image(logo)),
                    pw.Text(_user?.Shopname ?? 'Your Shop',
                        style: pw.TextStyle(font: ttf, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Mobile: ${_user?.mobile ?? '-'}',
                        style: pw.TextStyle(font: ttf, fontSize: 10)),
                    pw.Text('GSTIN: ${_user?.gstNumber ?? '-'}',
                        style: pw.TextStyle(font: ttf, fontSize: 10)),
                    pw.Text('Address: ${_user?.shopAddress ?? '-'}',
                        style: pw.TextStyle(font: ttf, fontSize: 10)),
                  ],
                ),
              ),
              pw.Divider(),

              // Invoice Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Invoice No: ${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                          style: pw.TextStyle(font: ttf, fontSize: 10)),
                      pw.Text('Date: ${DateFormat('dd-MM-yyyy').format(now)}',
                          style: pw.TextStyle(font: ttf, fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Time: ${DateFormat('hh:mm a').format(now)}',
                          style: pw.TextStyle(font: ttf, fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),

              // Customer Info
              pw.Text('Customer: ${widget.customer?.name ?? 'Walk-in Customer'}',
                  style: pw.TextStyle(font: ttf, fontSize: 10)),
              if (widget.customer?.mobile != null)
                pw.Text('Mobile: ${widget.customer!.mobile}',
                    style: pw.TextStyle(font: ttf, fontSize: 10)),
              pw.SizedBox(height: 10),
              pw.Divider(),

              // Items Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Item', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text('Qty', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text('Rate', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text('Amount', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ],
              ),
              pw.Divider(),

              // Items List
              ...widget.cartItems.map((item) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(item.name,
                        style: pw.TextStyle(font: ttf, fontSize: 10),
                        maxLines: 2),
                  ),
                  pw.Text('${item.quantity}',
                      style: pw.TextStyle(font: ttf, fontSize: 10)),
                  pw.Text('₹${item.price.toStringAsFixed(2)}',
                      style: pw.TextStyle(font: ttf, fontSize: 10)),
                  pw.Text('₹${(item.price * item.quantity).toStringAsFixed(2)}',
                      style: pw.TextStyle(font: ttf, fontSize: 10)),
                ],
              )),

              pw.Divider(),

              // Subtotal
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:', style: pw.TextStyle(font: ttf, fontSize: 10)),
                  pw.Text('₹${widget.totalAmount.toStringAsFixed(2)}',
                      style: pw.TextStyle(font: ttf, fontSize: 10)),
                ],
              ),

              // Discount
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Discount:', style: pw.TextStyle(font: ttf, fontSize: 10)),
                  pw.Text('-₹${widget.discount.toStringAsFixed(2)}',
                      style: pw.TextStyle(font: ttf, fontSize: 10)),
                ],
              ),

              // Tax Details if enabled
              if (_taxBillingEnabled) ...[
                pw.SizedBox(height: 5),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('CGST (2.5%):', style: pw.TextStyle(font: ttf, fontSize: 10)),
                    pw.Text('₹${totalCgst.toStringAsFixed(2)}', style: pw.TextStyle(font: ttf, fontSize: 10)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('SGST (2.5%):', style: pw.TextStyle(font: ttf, fontSize: 10)),
                    pw.Text('₹${totalSgst.toStringAsFixed(2)}', style: pw.TextStyle(font: ttf, fontSize: 10)),
                  ],
                ),
                if (totalIgst > 0) pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('IGST:', style: pw.TextStyle(font: ttf, fontSize: 10)),
                    pw.Text('₹${totalIgst.toStringAsFixed(2)}', style: pw.TextStyle(font: ttf, fontSize: 10)),
                  ],
                ),
                if (totalCess > 0) pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('CESS:', style: pw.TextStyle(font: ttf, fontSize: 10)),
                    pw.Text('₹${totalCess.toStringAsFixed(2)}', style: pw.TextStyle(font: ttf, fontSize: 10)),
                  ],
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Tax:', style: pw.TextStyle(font: ttf, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text('₹${totalTax.toStringAsFixed(2)}', style: pw.TextStyle(font: ttf, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],

              // Final Total
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Amount:', style: pw.TextStyle(font: ttf, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text('₹${widget.finalAmount.toStringAsFixed(2)}',
                      style: pw.TextStyle(font: ttf, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),

              // Payment Mode
              pw.SizedBox(height: 10),
              pw.Text('Payment Mode: ${widget.paymentMode.toUpperCase()}',
                  style: pw.TextStyle(font: ttf, fontSize: 10)),

              // Footer
              pw.SizedBox(height: 15),
              pw.Center(
                child: pw.Text('Thank you for your business!',
                    style: pw.TextStyle(font: ttf, fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text('Goods once sold will not be taken back',
                    style: pw.TextStyle(font: ttf, fontSize: 8)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Widget _buildCustomerInfo() {
    if (widget.customer == null) return const SizedBox();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.person, size: 40, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.customer!.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(widget.customer!.mobile),
                  if (widget.customer!.totalTransactions > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${widget.customer!.totalTransactions} purchases | ₹${widget.customer!.totalSpent.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(CartItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '${item.name} (x${item.quantity})',
              style: const TextStyle(fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '₹${(item.price * item.quantity).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
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

  Widget _buildPaymentInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                _getPaymentIcon(widget.paymentMode),
                color: AppColors.primaryColor,
              ),
              const SizedBox(width: 12),
              Text(
                widget.paymentMode.toUpperCase(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getPaymentIcon(String mode) {
    switch (mode) {
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'upi':
        return Icons.mobile_friendly;
      case 'wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccess) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'lib/assets/LottieFies/successfull.json',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              const Text(
                'Transaction Successful!',
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
    }

    // Calculate taxes if enabled
    double totalCgst = 0;
    double totalSgst = 0;
    double totalIgst = 0;
    double totalCess = 0;
    double totalTax = 0;

    if (_taxBillingEnabled) {
      totalCgst = widget.cartItems.fold(0.0, (sum, item) => sum + (item.cgst ?? 0) * item.quantity);
      totalSgst = widget.cartItems.fold(0.0, (sum, item) => sum + (item.sgst ?? 0) * item.quantity);
      totalIgst = widget.cartItems.fold(0.0, (sum, item) => sum + (item.igst ?? 0) * item.quantity);
      totalCess = widget.cartItems.fold(0.0, (sum, item) => sum + (item.cess ?? 0) * item.quantity);
      totalTax = totalCgst + totalSgst + totalIgst + totalCess;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Transaction'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCustomerInfo(),
                  const Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...widget.cartItems.map(_buildOrderItem),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow('Subtotal', widget.totalAmount),
                  _buildSummaryRow('Discount', widget.discount),

                  // Show tax details if enabled
                  if (_taxBillingEnabled) ...[
                    const SizedBox(height: 8),
                    _buildTaxRow('CGST (2.5%)', totalCgst),
                    _buildTaxRow('SGST (2.5%)', totalSgst),
                    if (totalIgst > 0) _buildTaxRow('IGST', totalIgst),
                    if (totalCess > 0) _buildTaxRow('CESS', totalCess),
                    _buildTaxRow('Total Tax', totalTax),
                    const SizedBox(height: 8),
                  ],

                  Container(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow(
                    'Total Amount',
                    widget.finalAmount,
                    isBold: true,
                  ),
                  const SizedBox(height: 24),
                  _buildPaymentInfo(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isProcessing ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: AppColors.primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('BACK'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _processTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isProcessing
                            ? const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        )
                            : const Text('CONFIRM'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _generatePdfBill,
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white ),
                  label: const Text('Generate PDF Bill', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}