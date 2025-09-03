import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../api/API.dart';
import '../../models/Transaction.dart';
import '../../models/User.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';


class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '₹');
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all';
  DateTime? _selectedDate;
  User? _currentUser;

  final Map<String, String> _filterOptions = {
    'all': 'All Transactions',
    'today': 'Today',
    'week': 'This Week',
    'month': 'This Month',
    'pending': 'Pending',
    'completed': 'Completed',
  };

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await apiServices.getProfile();
    if (userData.success && userData.user != null) {
      setState(() {
        _currentUser = userData.user;
      });
    }
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await apiServices.getTransactions();
      if (response.success) {
        setState(() {
          _transactions = response.data ?? [];
          _filteredTransactions = List.from(_transactions);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        //_showErrorSnackbar(response.message ?? 'Failed to load transactions');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackbar('An error occurred: $e');
    }
  }

  void _filterTransactions() {
    List<Transaction> filtered = List.from(_transactions);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((txn) {
        final id = txn.id.toLowerCase();
        final paymentMode = txn.paymentMode.toLowerCase() ?? '';
        return id.contains(_searchQuery.toLowerCase()) ||
            paymentMode.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply date filter
    if (_selectedDate != null) {
      filtered = filtered.where((txn) {
        return isSameDay(txn.createdAt, _selectedDate!);
      }).toList();
    }

    // Apply status filter
    switch (_selectedFilter) {
      case 'today':
        filtered = filtered.where((txn) {
          return isSameDay(txn.createdAt, DateTime.now());
        }).toList();
        break;
      case 'week':
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        filtered = filtered.where((txn) {
          return txn.createdAt.isAfter(startOfWeek);
        }).toList();
        break;
      case 'month':
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        filtered = filtered.where((txn) {
          return txn.createdAt.isAfter(startOfMonth);
        }).toList();
        break;
      case 'pending':
        filtered = filtered.where((txn) => txn.status == 'pending').toList();
        break;
      case 'completed':
        filtered = filtered.where((txn) => txn.status == 'completed').toList();
        break;
    }

    setState(() {
      _filteredTransactions = filtered;
    });
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _filterTransactions();
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
      _filterTransactions();
    });
  }


  Future<void> _exportToExcel() async {
    try {
      // Create Excel file
      final excel = Excel.createExcel();
      final sheet = excel['GST Transactions'];
      // Add headers
      sheet.appendRow([
        TextCellValue('Date'),
        TextCellValue('Transaction ID'),
        TextCellValue('Customer Name'),
        TextCellValue('Status'),
        TextCellValue('Payment Mode'),
        TextCellValue('Total Amount'),
        TextCellValue('Discount'),
        TextCellValue('Taxable Amount'),
        TextCellValue('CGST (9%)'),
        TextCellValue('SGST (9%)'),
        TextCellValue('IGST (18%)'),
        TextCellValue('Final Amount'),
      ]);

      // Add data rows
      for (final transaction in _filteredTransactions) {
        // Calculate GST values (adjust these calculations based on your GST rates)
        final taxableAmount = transaction.finalAmount / 1.18; // Assuming 18% GST
        final gstAmount = transaction.finalAmount - taxableAmount;

        sheet.appendRow([
          TextCellValue(_dateFormat.format(transaction.createdAt)),
          TextCellValue(transaction.id.substring(0, 8)),
          TextCellValue(_currentUser?.name ?? 'N/A'),
          TextCellValue(_capitalize(transaction.status ?? '')),
          TextCellValue(_capitalize(transaction.paymentMode ?? '')),
          TextCellValue(_currencyFormat.format(transaction.totalPrice)),
          TextCellValue(_currencyFormat.format(transaction.discount ?? 0)),
          TextCellValue(_currencyFormat.format(taxableAmount)),
          TextCellValue(_currencyFormat.format(gstAmount / 2)), // CGST half
          TextCellValue(_currencyFormat.format(gstAmount / 2)), // SGST half
          TextCellValue(_currencyFormat.format(gstAmount)),     // IGST full
          TextCellValue(_currencyFormat.format(transaction.finalAmount)),
        ]);
      }

      // Save the file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/gst_transactions_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      await file.writeAsBytes(excel.encode()!);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'GST Transactions Report',
        text: 'Here is the GST transactions report exported from the app.',
      );
    } catch (e) {
      _showErrorSnackbar('Failed to export Excel: $e');
    }
  }

  void _showTransactionDetails(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transaction #${transaction.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Date', _dateFormat.format(transaction.createdAt)),
              _buildDetailRow('Status', _capitalize(transaction.status ?? '')),
              _buildDetailRow('Payment Mode', _capitalize(transaction.paymentMode ?? '')),
              _buildDetailRow('Total Amount', _currencyFormat.format(transaction.totalPrice)),
              if (transaction.discount != null && transaction.discount! > 0)
                _buildDetailRow('Discount', _currencyFormat.format(transaction.discount!)),
              _buildDetailRow('Final Amount', _currencyFormat.format(transaction.finalAmount)),
              const SizedBox(height: 16),
              const Text(
                'Tax Breakdown',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              _buildDetailRow('Taxable Amount', _currencyFormat.format(
                  transaction.totalPrice - (transaction.totalCgst + transaction.totalSgst + transaction.totalIgst)
              )),
              _buildDetailRow('CGST', _currencyFormat.format(transaction.totalCgst)),
              _buildDetailRow('SGST', _currencyFormat.format(transaction.totalSgst)),
              _buildDetailRow('IGST', _currencyFormat.format(transaction.totalIgst)),
              _buildDetailRow('CESS', _currencyFormat.format(transaction.totalCess)),
              _buildDetailRow('Total Tax', _currencyFormat.format(transaction.totalTax)),

              const SizedBox(height: 16),
              const Text(
                'Items',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              ...transaction.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(item.productName),
                    ),
                    Expanded(
                      child: Text('${item.quantity} x ${_currencyFormat.format(item.price)}'),
                    ),
                    Expanded(
                      child: Text(
                        _currencyFormat.format(item.price * item.quantity),
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              if (transaction.status == 'pending')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await _completeTransaction(transaction.id);
                    },
                    child: const Text(
                      'Mark as Completed',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  Future<void> _completeTransaction(String transactionId) async {
    try {
      final response = await apiServices.completeTransaction(transactionId);

      if (response.success) {
        setState(() {
          final index = _transactions.indexWhere((t) => t.id == transactionId);
          if (index != -1) {
            _transactions[index] = _transactions[index].copyWith(status: 'completed');
            _filterTransactions();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Transaction marked as completed'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorSnackbar(response.message ?? 'Failed to complete transaction');
      }
    } catch (e) {
      _showErrorSnackbar('Failed to complete transaction: $e');
    }
  }

  Future<void> _deleteTransaction(String transactionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await apiServices.deleteTransaction(transactionId);

        if (response.success) {
          setState(() {
            _transactions.removeWhere((t) => t.id == transactionId);
            _filterTransactions();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Transaction deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _showErrorSnackbar(response.message ?? 'Failed to delete transaction');
        }
      } catch (e) {
        _showErrorSnackbar('Failed to delete transaction: $e');
      }
    }
  }


  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
    );

    if (picked != null) {
      setState(() {
        _filteredTransactions = _transactions.where((txn) {
          return txn.createdAt.isAfter(picked.start) &&
              txn.createdAt.isBefore(picked.end.add(const Duration(days: 1)));
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportToExcel,
            tooltip: 'Export to Excel',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _filterTransactions();
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedFilter,
                        items: _filterOptions.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedFilter = value ?? 'all';
                            _filterTransactions();
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Add the date range button here:
                    IconButton(
                      icon: const Icon(Icons.date_range),
                      onPressed: () => _selectDateRange(context),
                      tooltip: 'Select date range',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.calendar_today,
                        color: _selectedDate != null ? Theme.of(context).primaryColor : Colors.grey,
                      ),
                      onPressed: () => _selectDate(context),
                    ),
                    if (_selectedDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        onPressed: _clearDateFilter,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_filteredTransactions.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isNotEmpty || _selectedFilter != 'all' || _selectedDate != null
                          ? 'No matching transactions found'
                          : 'No transactions yet',
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    if (_searchQuery.isNotEmpty || _selectedFilter != 'all' || _selectedDate != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _selectedFilter = 'all';
                            _selectedDate = null;
                            _filterTransactions();
                          });
                        },
                        child: const Text('Clear filters'),
                      ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredTransactions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final transaction = _filteredTransactions[index];
                  return _buildTransactionCard(transaction);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showTransactionDetails(transaction),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${transaction.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Chip(
                    label: Text(
                      _capitalize(transaction.status ?? ''),
                      style: TextStyle(
                        color: transaction.status == 'completed'
                            ? Colors.green
                            : transaction.status == 'pending'
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                    backgroundColor: transaction.status == 'completed'
                        ? Colors.green.withOpacity(0.1)
                        : transaction.status == 'pending'
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _dateFormat.format(transaction.createdAt),
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.payment, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _capitalize(transaction.paymentMode ?? ''),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${transaction.items.length} item${transaction.items.length > 1 ? 's' : ''}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    _currencyFormat.format(transaction.finalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              if (transaction.status == 'pending')
                const SizedBox(height: 12),
              if (transaction.status == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _completeTransaction(transaction.id),
                        child: const Text('Complete'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        onPressed: () => _deleteTransaction(transaction.id),
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}