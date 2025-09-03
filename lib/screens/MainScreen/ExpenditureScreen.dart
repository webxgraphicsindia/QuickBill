import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quickbill/models/ApiResponse.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../api/API.dart';
import '../../constants/MonthlyData.dart';

class ExpenditureScreen extends StatefulWidget {
  const ExpenditureScreen({Key? key}) : super(key: key);

  @override
  _ExpenditureScreenState createState() => _ExpenditureScreenState();
}

class _ExpenditureScreenState extends State<ExpenditureScreen> {
  // Constants and Configuration
  static const List<String> _categories = [
    'Maintenance',
    'Utilities',
    'Supplies',
    'Rent',
    'Salaries',
    'Marketing',
    'Transportation',
    'Other'
  ];

  static const List<String> _paymentMethods = [
    'Cash',
    'Bank Transfer',
    'Credit Card',
    'Mobile Payment',
    'Other'
  ];

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // State Variables
  String _selectedCategory = _categories.first;
  String _selectedPaymentMethod = _paymentMethods.first;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _showForm = false;
  String? _editExpenditureId;
  List<dynamic> _expenditures = [];
  Map<String, dynamic>? _reportData;
  DateTimeRange? _dateRange;
  int _currentTabIndex = 0; // 0: List, 1: Dashboard, 2: Reports

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    _loadExpenditures();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ======================
  // Data Loading Methods
  // ======================

  Future<void> _loadExpenditures() async {
    setState(() => _isLoading = true);
    final response = await apiServices().getExpenditures();
    if (response.success) {
      setState(() {
        _expenditures = response.data!;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
     // _showErrorSnackbar(response.message ?? 'Failed to load expenditures');
    }
  }

  Future<void> _loadCategoryReport() async {
    setState(() => _isLoading = true);
    final response = await apiServices().getExpenditureCategoryReport();
    if (response.success) {
      setState(() {
        _reportData = {'type': 'category', 'data': response.data};
        _isLoading = false;
        _currentTabIndex = 2;
      });
    } else {
      setState(() => _isLoading = false);
     // _showErrorSnackbar(response.message ?? 'Failed to load report');
    }
  }

  Future<void> _loadDateRangeReport() async {
    if (_dateRange == null) return;

    setState(() => _isLoading = true);
    final response = await apiServices().getExpenditureDateRangeReport(
      startDate: DateFormat('yyyy-MM-dd').format(_dateRange!.start),
      endDate: DateFormat('yyyy-MM-dd').format(_dateRange!.end),
    );

    if (response.success) {
      setState(() {
        _reportData = {'type': 'dateRange', 'data': response.data};
        _isLoading = false;
        _currentTabIndex = 2;
      });
    } else {
      setState(() => _isLoading = false);
      //_showErrorSnackbar(response.message ?? 'Failed to load report');
    }
  }

  // ======================
  // UI Helper Methods
  // ======================

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _dateRange ?? DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _loadDateRangeReport();
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ======================
  // Form Handling Methods
  // ======================

  void _editExpenditure(Map<String, dynamic> expenditure) {
    setState(() {
      _editExpenditureId = expenditure['id'];
      _selectedCategory = expenditure['category'];
      _selectedPaymentMethod = expenditure['payment_method'] ?? 'Cash';
      _amountController.text = expenditure['amount'].toString();
      _descriptionController.text = expenditure['description'];
      _selectedDate = DateTime.parse(expenditure['date']);
      _dateController.text = expenditure['date'];
      _notesController.text = expenditure['notes'] ?? '';
      _showForm = true;
      _currentTabIndex = 0;
    });
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _editExpenditureId = null;
      _selectedCategory = _categories.first;
      _selectedPaymentMethod = _paymentMethods.first;
      _selectedDate = DateTime.now();
      _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      _amountController.clear();
      _descriptionController.clear();
      _notesController.clear();
      _showForm = false;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final expenditureData = {
      'category': _selectedCategory,
      'description': _descriptionController.text,
      'amount': double.parse(_amountController.text),
      'date': _dateController.text,
      'payment_method': _selectedPaymentMethod,
      'notes': _notesController.text,
    };

    ApiResponse response;
    if (_editExpenditureId != null) {
      response = await apiServices().updateExpenditure(
        _editExpenditureId!,
        expenditureData,
      );
    } else {
      response = await apiServices().createExpenditure(expenditureData);
    }

    setState(() => _isLoading = false);

    if (response.success) {
      _showErrorSnackbar(response.message ?? 'Expenditure saved successfully');
      _resetForm();
      _loadExpenditures();
    } else {
      _showErrorSnackbar(response.message ?? 'Failed to save expenditure');
    }
  }

  Future<void> _deleteExpenditure(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this expenditure?'),
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
    final response = await apiServices().deleteExpenditure(id);
    setState(() => _isLoading = false);

    if (response.success) {
      _showErrorSnackbar(response.message ?? 'Expenditure deleted successfully');
      _loadExpenditures();
    } else {
      _showErrorSnackbar(response.message ?? 'Failed to delete expenditure');
    }
  }

  // ======================
  // Widget Building Methods
  // ======================

  Widget _buildExpenditureForm() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _editExpenditureId != null ? 'Edit Expenditure' : 'Add New Expenditure',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 16),
              _buildAmountField(),
              const SizedBox(height: 16),
              _buildDateField(context),
              const SizedBox(height: 16),
              _buildPaymentMethodDropdown(),
              const SizedBox(height: 16),
              _buildNotesField(),
              const SizedBox(height: 24),
              _buildFormButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: _inputDecoration('Category'),
      items: _categories.map((category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedCategory = value!),
      validator: (value) => value == null ? 'Please select a category' : null,
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: _inputDecoration('Description'),
      validator: (value) => value == null || value.isEmpty
          ? 'Please enter a description' : null,
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: _inputDecoration('Amount', prefixText: '\₹ '),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter an amount';
        if (double.tryParse(value) == null) return 'Please enter a valid number';
        return null;
      },
    );
  }

  Widget _buildDateField(BuildContext context) {
    return TextFormField(
      controller: _dateController,
      decoration: _inputDecoration('Date',
          suffixIcon: Icon(Icons.calendar_today, color: Theme.of(context).primaryColor)),
      readOnly: true,
      onTap: () => _selectDate(context),
      validator: (value) => value == null || value.isEmpty
          ? 'Please select a date' : null,
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedPaymentMethod,
      decoration: _inputDecoration('Payment Method'),
      items: _paymentMethods.map((method) {
        return DropdownMenuItem<String>(
          value: method,
          child: Text(method),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: _inputDecoration('Notes (Optional)'),
      maxLines: 2,
    );
  }

  Widget _buildFormButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _isLoading ? null : _submitForm,
            child: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : Text(
              _editExpenditureId != null ? 'UPDATE' : 'SAVE',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(color: Theme.of(context).primaryColor),
            ),
            onPressed: _isLoading ? null : _resetForm,
            child: Text(
              'CANCEL',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String labelText,
      {String? prefixText, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      prefixText: prefixText,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  Widget _buildExpenditureList() {
    if (_expenditures.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long,
        message: 'No expenditures recorded yet',
        actionText: 'Add Your First Expenditure',
        onAction: () => setState(() => _showForm = true),
      );
    }

    final totalExpenditure = _expenditures.fold(
        0.0, (sum, item) => sum + double.parse(item['amount'].toString()));

    return Column(
      children: [
        _buildTotalExpenditureCard(totalExpenditure),
        Expanded(
          child: ListView.builder(
            itemCount: _expenditures.length,
            itemBuilder: (context, index) {
              final expenditure = _expenditures[index];
              return _buildExpenditureListItem(expenditure);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTotalExpenditureCard(double total) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Expenditure',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\₹${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
              Chip(
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                label: Text(
                  '${_expenditures.length} items',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenditureListItem(Map<String, dynamic> expenditure) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getCategoryColor(expenditure['category']).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(expenditure['category']),
            color: _getCategoryColor(expenditure['category']),
          ),
        ),
        title: Text(
          expenditure['description'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${expenditure['category']} • ${DateFormat('MMM d, y').format(DateTime.parse(expenditure['date']))}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (expenditure['notes'] != null && expenditure['notes'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  expenditure['notes'],
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\₹${double.parse(expenditure['amount'].toString()).toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              expenditure['payment_method'] ?? 'Cash',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () => _editExpenditure(expenditure),
      ),
    );
  }

  Widget _buildDashboard() {
    if (_expenditures.isEmpty) {
      return _buildEmptyState(
        icon: Icons.analytics,
        message: 'No data to display',
        actionText: 'Add Your First Expenditure',
        onAction: () {
          setState(() {
            _showForm = true;
            _currentTabIndex = 0;
          });
        },
      );
    }

    // Calculate dashboard metrics
    final totalExpenditure = _expenditures.fold(
        0.0, (sum, item) => sum + double.parse(item['amount'].toString()));

    // Group by category
    final categoryMap = <String, double>{};
    for (var exp in _expenditures) {
      final category = exp['category'];
      final amount = double.parse(exp['amount'].toString());
      categoryMap[category] = (categoryMap[category] ?? 0) + amount;
    }

    // Group by payment method
    final paymentMap = <String, double>{};
    for (var exp in _expenditures) {
      final method = exp['payment_method'] ?? 'Cash';
      final amount = double.parse(exp['amount'].toString());
      paymentMap[method] = (paymentMap[method] ?? 0) + amount;
    }

    // Group by month and sort chronologically
    final monthlyMap = <String, double>{};
    for (var exp in _expenditures) {
      final date = DateTime.parse(exp['date']);
      final monthKey = DateFormat('MMM y').format(date);
      final amount = double.parse(exp['amount'].toString());
      monthlyMap[monthKey] = (monthlyMap[monthKey] ?? 0) + amount;
    }

    final monthlyData = monthlyMap.entries.map((e) {
      return MonthlyData(
        month: e.key,
        date: DateFormat('MMM y').parse(e.key),
        amount: e.value,
      );
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    final categoryData = categoryMap.entries
        .map((e) => {'category': e.key, 'amount': e.value})
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 768;
        final isTablet = constraints.maxWidth > 600;

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : 16,
              vertical: 16,
            ),
            child: Column(
              children: [
                // Summary Cards - Responsive Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isDesktop ? 3 : (isTablet ? 2 : 1),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: isDesktop ? 1.5 : (isTablet ? 1.8 : 2.0),
                  children: [
                    _buildSummaryCard(
                      title: 'Total Expenditure',
                      value: totalExpenditure,
                      icon: Icons.account_balance_wallet,
                      color: Colors.blue,
                    ),
                    _buildSummaryCard(
                      title: 'Transactions',
                      value: _expenditures.length.toDouble(),
                      icon: Icons.receipt,
                      color: Colors.green,
                    ),
                    _buildSummaryCard(
                      title: 'Avg. Transaction',
                      value: totalExpenditure / _expenditures.length,
                      icon: Icons.attach_money,
                      color: Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Main Charts Section - Responsive Layout
                if (isDesktop) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildCategoryChart(categoryData, totalExpenditure),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: _buildMonthlyTrendChart(monthlyData.cast<Map<String, dynamic>>()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentMethodChart(paymentMap),
                ] else ...[
                  _buildCategoryChart(categoryData, totalExpenditure),
                  const SizedBox(height: 16),
                  _buildMonthlyTrendChart(monthlyData.cast<Map<String, dynamic>>()),
                  const SizedBox(height: 16),
                  _buildPaymentMethodChart(paymentMap),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              title == 'Transactions'
                  ? value.toInt().toString()
                  : '\₹${value.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (title == 'Avg. Transaction') ...[
              const SizedBox(height: 4),
              Text(
                'per transaction',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart(List<Map<String, dynamic>> data, double total) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expenditure by Category',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 300,
              child: SfCircularChart(
                legend: Legend(
                  isVisible: true,
                  overflowMode: LegendItemOverflowMode.wrap,
                  position: LegendPosition.bottom,
                ),
                series: <CircularSeries>[
                  PieSeries<Map<String, dynamic>, String>(
                    dataSource: data,
                    xValueMapper: (data, _) => data['category'],
                    yValueMapper: (data, _) => data['amount'],
                    dataLabelMapper: (data, _) =>
                    '${(data['amount'] / total * 100).toStringAsFixed(1)}%',
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                    ),
                    pointColorMapper: (data, _) =>
                        _getCategoryColor(data['category']),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTrendChart(List<Map<String, dynamic>> data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Expenditure Trend',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                primaryYAxis: NumericAxis(
                  numberFormat: NumberFormat.currency(symbol: '₹'),
                ),
                series: <CartesianSeries<dynamic, dynamic>>[
                  ColumnSeries<dynamic, String>(
                    dataSource: data,
                    xValueMapper: (data, _) => data['month'] as String,
                    yValueMapper: (data, _) => data['amount'] as double,
                    color: Theme.of(context).primaryColor,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelAlignment: ChartDataLabelAlignment.top,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodChart(Map<String, double> data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Methods',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: SfCircularChart(
                series: <CircularSeries<dynamic, dynamic>>[
                  DoughnutSeries<MapEntry<String, double>, String>(
                    dataSource: data.entries.toList(),
                    xValueMapper: (data, _) => data.key,
                    yValueMapper: (data, _) => data.value,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.inside,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportView() {
    if (_reportData == null) {
      return _buildEmptyState(
        icon: Icons.assignment,
        message: 'Select a report type to view data',
        actionText: 'View Category Report',
        secondaryActionText: 'View Date Range Report',
        onAction: _loadCategoryReport,
        onSecondaryAction: () => _selectDateRange(context),
      );
    }

    if (_reportData!['type'] == 'category') {
      return _buildCategoryReportView();
    } else if (_reportData!['type'] == 'dateRange') {
      return _buildDateRangeReportView();
    }

    return Container();
  }

  Widget _buildCategoryReportView() {
    final data = _reportData!['data'] as List;
    final total = data.fold(0.0, (sum, item) => sum + item['total']);

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildPieChartCard(data, total),
          _buildCategoryBreakdownCard(data, total),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(List<dynamic> data, double total) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Expenditure by Category',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: SfCircularChart(
                legend: Legend(
                  isVisible: true,
                  overflowMode: LegendItemOverflowMode.wrap,
                ),
                series: <CircularSeries>[
                  PieSeries<dynamic, String>(
                    dataSource: data,
                    xValueMapper: (data, _) => data['category'],
                    yValueMapper: (data, _) => data['total'],
                    dataLabelMapper: (data, _) =>
                    '${(data['total'] / total * 100).toStringAsFixed(1)}%',
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                    ),
                    pointColorMapper: (data, _) =>
                        _getCategoryColor(data['category']),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdownCard(List<dynamic> data, double total) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: const Text('Total Expenditure'),
              trailing: Text(
                '\₹${total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const Divider(),
            ...data.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(item['category'])),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: item['total'] / total,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                            _getCategoryColor(item['category'])),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\₹${item['total'].toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeReportView() {
    final data = _reportData!['data'] as List;
    final total = data.fold(0.0, (sum, item) => sum + item['amount']);

    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Expenditure from ${DateFormat('MMM d, y').format(_dateRange!.start)} to ${DateFormat('MMM d, y').format(_dateRange!.end)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Total Expenditure'),
                    trailing: Text(
                      '\₹${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const Divider(),
                  ...data.map((item) {
                    return ListTile(
                      title: Text(item['description']),
                      subtitle: Text(
                          '${item['category']} • ${DateFormat('MMM d, y').format(DateTime.parse(item['date']))}'),
                      trailing: Text(
                        '\₹${item['amount'].toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String actionText,
    String? secondaryActionText,
    required VoidCallback onAction,
    VoidCallback? onSecondaryAction,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onAction,
            child: Text(actionText),
          ),
          if (secondaryActionText != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onSecondaryAction,
              child: Text(secondaryActionText),
            ),
          ],
        ],
      ),
    );
  }

  // ======================
  // Helper Methods
  // ======================

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Maintenance': return Colors.blue;
      case 'Utilities': return Colors.green;
      case 'Supplies': return Colors.orange;
      case 'Rent': return Colors.purple;
      case 'Salaries': return Colors.red;
      case 'Marketing': return Colors.teal;
      case 'Transportation': return Colors.indigo;
      default: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Maintenance': return Icons.handyman;
      case 'Utilities': return Icons.bolt;
      case 'Supplies': return Icons.inventory;
      case 'Rent': return Icons.home;
      case 'Salaries': return Icons.people;
      case 'Marketing': return Icons.campaign;
      case 'Transportation': return Icons.directions_car;
      case 'Other': return Icons.category;
      default: return Icons.receipt;
    }
  }

  // ======================
  // Main Build Method
  // ======================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenditure Management'),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.add),
          //   onPressed: () {
          //     setState(() {
          //       _showForm = true;
          //       _reportData = null;
          //       _currentTabIndex = 0;
          //     });
          //   },
          //   tooltip: 'Add New Expenditure',
          // ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          if (_showForm) _buildExpenditureForm(),
          if (!_showForm)
            Expanded(
              child: DefaultTabController(
                length: 3,
                initialIndex: _currentTabIndex,
                child: Column(
                  children: [
                    Material(
                      color: Theme.of(context).appBarTheme.backgroundColor,
                      child: TabBar(
                        onTap: (index) => setState(() => _currentTabIndex = index),
                        tabs: const [
                          Tab(icon: Icon(Icons.list), text: 'Transactions'),
                          Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
                          Tab(icon: Icon(Icons.analytics), text: 'Reports'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildExpenditureList(),
                          _buildDashboard(),
                          _buildReportView(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _showForm || _currentTabIndex != 0
          ? null
          : FloatingActionButton(
        onPressed: () => setState(() => _showForm = true),
        child: const Icon(Icons.add),
        tooltip: 'Add New Expenditure',
      ),
    );
  }
}