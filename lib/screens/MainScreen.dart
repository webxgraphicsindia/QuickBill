import 'package:flutter/material.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';
import 'MainScreen/CreateTransactionScreen.dart';
import 'MainScreen/DashboardScreen.dart';
import 'MainScreen/ExpenditureScreen.dart';
import 'MainScreen/InventoryScreen.dart';
import 'MainScreen/ProfileScreen.dart';
import 'MainScreen/TransactionsScreen.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CreateTransactionScreen(),
    const InventoryScreen(),
    const TransactionsScreen(),
    const DashboardScreen(),
    const ExpenditureScreen(), // Added expenditure screen
  ];

  final List<String> _screenTitles = [
    'Create Transaction',
    'Inventory',
    'Transactions',
    'Dashboard',
    'Expenditure'
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final isLargeTablet = MediaQuery.of(context).size.width >= 600;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: isDesktop || isLargeTablet
          ? _buildDesktopAppBar(theme)
          : _buildMobileAppBar(theme),
      body: isDesktop || isLargeTablet
          ? _buildDesktopLayout(isLargeTablet)
          : _buildMobileLayout(),
      bottomNavigationBar: isDesktop || isLargeTablet
          ? null
          : _buildMobileBottomBar(),
      drawer: isDesktop || isLargeTablet
          ? null
          : _buildMobileDrawer(),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(ThemeData theme) {
    return AppBar(
      title: Text(
        "Quick Bill",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onPrimary,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: theme.primaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.2),
            child: IconButton(
              icon: const Icon(Icons.person_outline, size: 22),
              color: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
          ),
        ),
      ],
      automaticallyImplyLeading: false,
    );
  }

  PreferredSizeWidget _buildDesktopAppBar(ThemeData theme) {
    return AppBar(
      title: Text(
        "Quick Bill - ${_screenTitles[_currentIndex]}",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onPrimary,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: theme.primaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.2),
            child: IconButton(
              icon: const Icon(Icons.person_outline, size: 22),
              color: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
          ),
        ),
      ],
      automaticallyImplyLeading: false,
    );
  }

  Widget _buildMobileLayout() {
    return _screens[_currentIndex];
  }

  Widget _buildDesktopLayout(bool isLargeTablet) {
    return Row(
      children: [
        // Side Navigation
        Container(
          width: isLargeTablet ? 180 : 200,
          color: Theme.of(context).primaryColor.withOpacity(0.05),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildDesktopNavItem(0, Icons.home, 'Home'),
              _buildDesktopNavItem(1, Icons.inventory, 'Inventory'),
              _buildDesktopNavItem(2, Icons.receipt, 'Transactions'),
              _buildDesktopNavItem(3, Icons.dashboard, 'Dashboard'),
              _buildDesktopNavItem(4, Icons.money_off, 'Expenditure'),
              const Spacer(),
              const SizedBox(height: 20),
            ],
          ),
        ),
        // Main Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _screens[_currentIndex],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopNavItem(int index, IconData icon, String label, {bool isProfile = false}) {
    return ListTile(
      leading: Icon(
        icon,
        color: _currentIndex == index && !isProfile
            ? Theme.of(context).primaryColor
            : Colors.grey,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: _currentIndex == index && !isProfile
              ? FontWeight.bold
              : null,
          color: _currentIndex == index && !isProfile
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
      ),
      tileColor: _currentIndex == index && !isProfile
          ? Theme.of(context).primaryColor.withOpacity(0.1)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }

  Widget _buildMobileBottomBar() {
    return StylishBottomBar(
      option: BubbleBarOptions(
        barStyle: BubbleBarStyle.horizontal,
        bubbleFillStyle: BubbleFillStyle.fill,
        opacity: 0.3,
        inkColor: Colors.white,
      ),
      items: [
        BottomBarItem(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          selectedColor: Colors.blue,
          title: const Text('Home'),
        ),
        BottomBarItem(
          icon: const Icon(Icons.inventory_outlined),
          selectedIcon: const Icon(Icons.inventory),
          selectedColor: Colors.amber,
          title: const Text('Inventory'),
        ),
        BottomBarItem(
          icon: const Icon(Icons.receipt_outlined),
          selectedIcon: const Icon(Icons.receipt),
          selectedColor: Colors.purple,
          title: const Text('Transactions'),
        ),
        BottomBarItem(
          icon: const Icon(Icons.dashboard_outlined),
          selectedIcon: const Icon(Icons.dashboard),
          selectedColor: Colors.green,
          title: const Text('Dashboard'),
        ),
        BottomBarItem(
          icon: const Icon(Icons.money_off_outlined),
          selectedIcon: const Icon(Icons.money_off),
          selectedColor: Colors.red,
          title: const Text('Expenditure'),
        ),
      ],
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: const Text(
              'Quick Bill',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildMobileDrawerItem(0, Icons.home, 'Home'),
          _buildMobileDrawerItem(1, Icons.inventory, 'Inventory'),
          _buildMobileDrawerItem(2, Icons.receipt, 'Transactions'),
          _buildMobileDrawerItem(3, Icons.dashboard, 'Dashboard'),
          _buildMobileDrawerItem(4, Icons.money_off, 'Expenditure'),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawerItem(int index, IconData icon, String title) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _currentIndex == index,
      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
        Navigator.pop(context);
      },
    );
  }
}