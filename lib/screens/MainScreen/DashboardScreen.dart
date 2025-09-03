import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quickbill/api/API.dart';
import 'package:quickbill/models/TransactionSummary.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../constants/Colors.dart';
import '../../models/DailyData.dart';
import 'CreateTransactionScreen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TransactionSummary? _summary;
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _paymentModeData = [];
  List<DailyData> _weeklyData = [];
  List<DailyData> _monthlyData = [];
  List<DailyData> _yearlyData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData({DateTime? date}) async {
    setState(() => _isLoading = true);
    try {
      final selectedDate = date ?? _selectedDate;
      final response = await apiServices.getTransactionSummary(
        date: selectedDate,
      );

      if (response.success && response.data != null) {
        setState(() {
          _summary = response.data!;
          _selectedDate = selectedDate;

          // Process payment mode data
          _paymentModeData = _summary!.byPaymentMode.map((mode) {
            return {
              'mode': mode['payment_mode'] ?? 'Unknown',
              'amount': mode['total'] ?? 0.0,
              'color': _getPaymentModeColor(mode['payment_mode'] ?? 'Unknown')
            };
          }).toList();

          // Generate chart data
          _generateChartData();
        });
      } else {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text(response.message ?? 'Failed to load data')),
        // );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  DateTime _getEndOfWeek(DateTime date) {
    return date.add(Duration(days: DateTime.daysPerWeek - date.weekday));
  }

  void _generateChartData() {
    final now = DateTime.now();

    // Weekly data
    _weeklyData = List.generate(7, (index) {
      final date = _getStartOfWeek(_selectedDate).add(Duration(days: index));
      return DailyData(
        day: DateFormat('E').format(date),
        amount: (date.day == now.day && date.month == now.month && date.year == now.year)
            ? _summary!.todayTotal
            : _summary!.weeklyTotal / 7,
      );
    });

    // Monthly data
    final daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    _monthlyData = List.generate(daysInMonth, (index) {
      final date = DateTime(_selectedDate.year, _selectedDate.month, index + 1);
      return DailyData(
        day: DateFormat('d').format(date),
        amount: (date.day == now.day && date.month == now.month && date.year == now.year)
            ? _summary!.todayTotal
            : _summary!.monthlyTotal / daysInMonth,
      );
    });

    // Yearly data
    _yearlyData = List.generate(12, (index) {
      final date = DateTime(_selectedDate.year, index + 1, 1);
      return DailyData(
        day: DateFormat('MMM').format(date),
        amount: (date.month == now.month && date.year == now.year)
            ? _summary!.monthlyTotal
            : _summary!.yearlyTotal / 12,
      );
    });
  }

  Color _getPaymentModeColor(String mode) {
    switch (mode.toLowerCase()) {
      case 'cash':
        return AppColors.primaryColor;
      case 'card':
        return Colors.blueAccent;
      case 'upi':
        return Colors.green;
      case 'wallet':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  Widget _buildSummaryCard(String title, double amount, IconData icon) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primaryColor,
                    size: isSmallScreen ? 16 : 20,
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 4 : 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '₹${NumberFormat("#,##0.00").format(amount)}',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkPurple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<DailyData> data, String title, {bool isBar = false}) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Column(
      children: [
        SizedBox(
          height: isSmallScreen ? 160 : 200,
          child: SfCartesianChart(
            primaryXAxis: CategoryAxis(
              labelRotation: isBar ? 0 : -45,
              labelStyle: TextStyle(
                color: Colors.grey.shade600,
                fontSize: isSmallScreen ? 10 : 12,
              ),
            ),
            primaryYAxis: NumericAxis(
              numberFormat: NumberFormat.compactCurrency(
                symbol: '₹',
                decimalDigits: 0,
              ),
            ),
            tooltipBehavior: TooltipBehavior(enable: true),
            series: <CartesianSeries>[
              if (isBar)
                BarSeries<DailyData, String>(
                  dataSource: data,
                  xValueMapper: (data, _) => data.day,
                  yValueMapper: (data, _) => data.amount,
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(5),
                  dataLabelSettings: DataLabelSettings(
                    isVisible: !isSmallScreen,
                    labelAlignment: ChartDataLabelAlignment.auto,
                  ),
                )
              else
                LineSeries<DailyData, String>(
                  dataSource: data,
                  xValueMapper: (data, _) => data.day,
                  yValueMapper: (data, _) => data.amount,
                  color: AppColors.primaryColor,
                  markerSettings: MarkerSettings(isVisible: true),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
            fontSize: isSmallScreen ? 12 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentModeChart() {
    if (_paymentModeData.isEmpty) {
      return Center(
        child: Text(
          'No payment data available',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return SizedBox(
      height: isSmallScreen ? 220 : 250,
      child: Column(
        children: [
          Expanded(
            child: SfCircularChart(
              legend: Legend(
                isVisible: true,
                position: LegendPosition.bottom,
                overflowMode: LegendItemOverflowMode.wrap,
                textStyle: TextStyle(
                  fontSize: isSmallScreen ? 10 : 12,
                ),
              ),
              series: <CircularSeries>[
                DoughnutSeries<Map<String, dynamic>, String>(
                  dataSource: _paymentModeData,
                  xValueMapper: (data, _) => data['mode'].toString(),
                  yValueMapper: (data, _) => data['amount'],
                  pointColorMapper: (data, _) => data['color'],
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    labelPosition: ChartDataLabelPosition.outside,
                    connectorLineSettings: ConnectorLineSettings(
                      type: ConnectorType.curve,
                      length: '10%',
                    ),
                    textStyle: TextStyle(
                      fontSize: isSmallScreen ? 10 : 12,
                    ),
                  ),
                  radius: '70%',
                  innerRadius: '50%',
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _paymentModeData.map((mode) {
              return Chip(
                backgroundColor: mode['color'].withOpacity(0.2),
                label: Text(
                  '${mode['mode']}: ₹${NumberFormat("#,##0.00").format(mode['amount'])}',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: isSmallScreen ? 10 : 12,
                  ),
                ),
                avatar: CircleAvatar(
                  backgroundColor: mode['color'],
                  radius: 6,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      await _loadData(date: picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App?'),
            content: const Text('Do you want to exit the application?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        backgroundColor: AppColors.lightPurple,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            'QuickBill Dashboard',
            style: TextStyle(fontSize: isSmallScreen ? 18 : 20),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, size: isSmallScreen ? 20 : 24),
              onPressed: _loadData,
            ),
            // if (isDesktop)
            //   IconButton(
            //     icon: Icon(Icons.add, size: isSmallScreen ? 20 : 24),
            //     onPressed: () {
            //       Navigator.push(
            //         context,
            //         MaterialPageRoute(
            //           builder: (context) => const CreateTransactionScreen(),
            //         ),
            //       ).then((_) => _loadData());
            //     },
            //   ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: _loadData,
          child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
        ),
        floatingActionButton: !isDesktop
            ? FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateTransactionScreen(),
              ),
            ).then((_) => _loadData());
          },
          backgroundColor: AppColors.primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        )
            : null,
      ),
    );
  }

  Widget _buildMobileLayout() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final crossAxisCount = screenWidth < 400 ? 2 : 2;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        children: [
          _buildDateSelector(),
          const SizedBox(height: 8),
          _buildSummaryCardsGrid(crossAxisCount: crossAxisCount),
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 16),
            child: _buildPaymentModeSection(),
          ),
          const SizedBox(height: 8),
          _buildTabSection(),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDateSelector(),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildSummaryCardsGrid(crossAxisCount: 4),
                    const SizedBox(height: 16),
                    _buildTabSection(),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildPaymentModeSection(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  size: isSmallScreen ? 16 : 20,
                ),
                onPressed: () {
                  final newDate = _selectedDate.subtract(const Duration(days: 1));
                  _loadData(date: newDate);
                },
              ),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      isSmallScreen
                          ? DateFormat('MMM d').format(_selectedDate)
                          : DateFormat('EEE, MMM d').format(_selectedDate),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.arrow_forward_ios,
                  size: isSmallScreen ? 16 : 20,
                ),
                onPressed: () {
                  if (!_selectedDate.isAfter(DateTime.now())) {
                    final newDate = _selectedDate.add(const Duration(days: 1));
                    _loadData(date: newDate);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCardsGrid({required int crossAxisCount}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final cardPadding = isSmallScreen ? 6.0 : 12.0;
    final cardAspectRatio = isSmallScreen ? 1.1 : (crossAxisCount == 2 ? 1.5 : 1.2);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: cardPadding),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        childAspectRatio: cardAspectRatio,
        crossAxisSpacing: cardPadding,
        mainAxisSpacing: cardPadding,
        children: [
          _buildSummaryCard(
            isSmallScreen ? "Today" : "Today's Sales",
            _summary?.todayTotal ?? 0,
            Icons.today,
          ),
          _buildSummaryCard(
            isSmallScreen ? "Week" : "This Week",
            _summary?.weeklyTotal ?? 0,
            Icons.calendar_view_week,
          ),
          _buildSummaryCard(
            isSmallScreen ? "Month" : "This Month",
            _summary?.monthlyTotal ?? 0,
            Icons.calendar_today,
          ),
          _buildSummaryCard(
            isSmallScreen ? "Year" : "This Year",
            _summary?.yearlyTotal ?? 0,
            Icons.calendar_view_month,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentModeSection() {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Mode Breakdown',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
            const SizedBox(height: 8),
            _buildPaymentModeChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSection() {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 12),
      child: Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryColor,
                unselectedLabelColor: Colors.grey,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.primaryColor.withOpacity(0.1),
                ),
                isScrollable: true,
                labelPadding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 12,
                ),
                tabs: [
                  Tab(text: isSmallScreen ? 'Week' : 'Weekly'),
                  Tab(text: isSmallScreen ? 'Month' : 'Monthly'),
                  Tab(text: isSmallScreen ? 'Year' : 'Yearly'),
                  Tab(text: isSmallScreen ? 'Pay' : 'Payments'),
                ],
              ),
            ),
          ),
          SizedBox(
            height: isSmallScreen ? 220 : 280,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Weekly Trend
                Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
                  child: _buildChart(
                    _weeklyData,
                    'Weekly Sales Trend',
                  ),
                ),
                // Monthly Trend
                Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
                  child: _buildChart(
                    _monthlyData,
                    'Monthly Sales Trend',
                    isBar: true,
                  ),
                ),
                // Yearly Trend
                Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
                  child: _buildChart(
                    _yearlyData,
                    'Yearly Sales Trend',
                  ),
                ),
                // Payment Methods
                Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
                  child: _buildPaymentModeList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentModeList() {
    if (_paymentModeData.isEmpty) {
      return const Center(child: Text('No payment data available'));
    }

    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return ListView.builder(
      itemCount: _paymentModeData.length,
      itemBuilder: (context, index) {
        final mode = _paymentModeData[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: mode['color'],
              radius: isSmallScreen ? 14 : 18,
              child: Text(
                mode['mode'][0].toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
            ),
            title: Text(
              mode['mode'].toString().toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
            trailing: Text(
              '₹${NumberFormat("#,##0.00").format(mode['amount'])}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
          ),
        );
      },
    );
  }
}