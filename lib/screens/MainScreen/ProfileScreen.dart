import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:quickbill/api/API.dart';
import 'package:quickbill/models/User.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

import '../../constants/Colors.dart';
import 'ChangePasswordScreen.dart';
import 'EditProfileScreen.dart';
import 'HelpSupportScreen.dart';
import 'PrivacyPolicyScreen.dart';
import 'RateAppScreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();
  User? _user;
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _fingerprintEnabled = false;
  bool _darkModeEnabled = false;
  bool _taxBillingEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSettings();
  }

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      title: const Text('Profile'),
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    );
  }

  PreferredSizeWidget _buildDesktopAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text('Profile'),
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    );
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

  Future<void> _editProfile() async {
    if (_user == null) return;

    setState(() => _isLoading = true);

    try {
      final profileResponse = await apiServices.getProfile();

      if (profileResponse.success) {
        final editedUser = await Navigator.push<User>(
          context,
          MaterialPageRoute(
            builder: (context) => EditProfileScreen(user: profileResponse.user ?? _user!),
          ),
        );

        if (editedUser != null) {
          setState(() {
            _user = editedUser;
          });
          await _storage.write(
              key: 'user_details',
              value: jsonEncode(editedUser.toJson())
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChangePasswordScreen(),
      ),
    );
  }

  Future<void> _loadSettings() async {
    final fingerprintSetting = await _storage.read(key: 'fingerprint_enabled');
    final notificationsSetting = await _storage.read(key: 'notifications_enabled');
    final darkModeSetting = await _storage.read(key: 'dark_mode_enabled');
    final taxBillingSetting = await _storage.read(key: 'tax_billing_enabled');

    setState(() {
      _fingerprintEnabled = fingerprintSetting == 'true';
      _notificationsEnabled = notificationsSetting != 'false';
      _darkModeEnabled = darkModeSetting == 'true';
      _taxBillingEnabled = taxBillingSetting == 'true';
    });
  }

  Future<void> _toggleTaxBilling(bool value) async {
    await _storage.write(key: 'tax_billing_enabled', value: value.toString());
    setState(() => _taxBillingEnabled = value);
  }

  Future<void> _toggleFingerprintAuth(bool value) async {
    try {
      if (value) {
        final canAuthenticate = await _localAuth.canCheckBiometrics;
        if (!canAuthenticate) {
          _showBiometricError('Biometric authentication not available');
          return;
        }

        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        if (availableBiometrics.isEmpty) {
          _showBiometricError('No biometric sensors available');
          return;
        }

        final didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Authenticate to enable fingerprint login',
          options: const AuthenticationOptions(
            biometricOnly: true,
            useErrorDialogs: true,
            stickyAuth: true,
          ),
        );

        if (didAuthenticate) {
          await _storage.write(key: 'fingerprint_enabled', value: 'true');
          setState(() => _fingerprintEnabled = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fingerprint lock enabled')),
          );
        }
      } else {
        await _storage.write(key: 'fingerprint_enabled', value: 'false');
        setState(() => _fingerprintEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fingerprint lock disabled')),
        );
      }
    } on PlatformException catch (e) {
      _showBiometricError('Authentication failed: ${e.message}');
    }
  }

  void _showBiometricError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _toggleNotifications(bool value) async {
    await _storage.write(key: 'notifications_enabled', value: value.toString());
    setState(() => _notificationsEnabled = value);
  }

  Future<void> _toggleDarkMode(bool value) async {
    await _storage.write(key: 'dark_mode_enabled', value: value.toString());
    setState(() => _darkModeEnabled = value);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')
          ),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout')
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await apiServices.logout();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Widget _buildProfileHeader() {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Column(
      children: [
        CircleAvatar(
          radius: isDesktop ? 60 : 50,
          backgroundColor: AppColors.primaryColor.withOpacity(0.2),
          child: _user?.profileImage != null && _user!.profileImage!.isNotEmpty
              ? ClipOval(
            child: Image.network(
              _user!.profileImage!,
              width: isDesktop ? 120 : 100,
              height: isDesktop ? 120 : 100,
              fit: BoxFit.cover,
            ),
          )
              : Icon(
            Icons.person,
            size: isDesktop ? 60 : 50,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _user?.name ?? 'User',
          style: TextStyle(
            fontSize: isDesktop ? 28 : 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (_user?.email != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _user!.email!,
              style: TextStyle(
                fontSize: isDesktop ? 18 : 16,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _editProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 24,
              vertical: isDesktop ? 16 : 12,
            ),
          ),
          child: Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: isDesktop ? 18 : 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
      IconData icon,
      String title,
      String subtitle,
      bool value,
      Function(bool) onChanged,
      ) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      secondary: Icon(icon, color: AppColors.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primaryColor,
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'SETTINGS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          elevation: 2,
          child: Column(
            children: [
              _buildSettingsItem(
                Icons.notifications,
                'Enable Notifications',
                'Receive app notifications',
                _notificationsEnabled,
                _toggleNotifications,
              ),
              const Divider(height: 1),
              _buildSettingsItem(
                Icons.fingerprint,
                'Fingerprint Lock',
                'Secure your app with biometrics',
                _fingerprintEnabled,
                _toggleFingerprintAuth,
              ),
              // const Divider(height: 1),
              // _buildSettingsItem(
              //   Icons.dark_mode,
              //   'Dark Mode',
              //   'Switch to dark theme',
              //   _darkModeEnabled,
              //   _toggleDarkMode,
              // ),
              const Divider(height: 1),
              _buildSettingsItem(
                Icons.receipt,
                'Tax Billing',
                'Enable tax calculation in bills',
                _taxBillingEnabled,
                _toggleTaxBilling,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem(
      IconData icon,
      String title,
      Widget screen, {
        bool isNavigation = true,
        Function()? onTap,
      }) {
    return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    leading: Icon(icon, color: AppColors.primaryColor),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right),
    onTap: isNavigation
    ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => screen)
    ): onTap,
    );
  }

  Widget _buildActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'ACTIONS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          elevation: 2,
          child: Column(
            children: [
              _buildActionItem(
                Icons.help,
                'Help & Support',
                const HelpSupportScreen(),
              ),
              const Divider(height: 1),
              _buildActionItem(
                Icons.privacy_tip,
                'Privacy Policy',
                const PrivacyPolicyScreen(),
              ),
              const Divider(height: 1),
              _buildActionItem(
                Icons.star,
                'Rate App',
                const RateAppScreen(),
              ),
              const Divider(height: 1),
              _buildActionItem(
                Icons.lock,
                'Change Password',
                const ChangePasswordScreen(),
                isNavigation: false,
                onTap: _changePassword,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return SizedBox(
      width: isDesktop ? 400 : double.infinity,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 16),
        child: ElevatedButton(
          onPressed: _logout,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Logout'),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16), // Added bottom padding
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildSettingsSection(),
            const SizedBox(height: 16),
            _buildActionsSection(),
            const SizedBox(height: 16),
            _buildLogoutButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _buildProfileHeader(),
                    const SizedBox(height: 40),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildSettingsSection(),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildActionsSection(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: _buildLogoutButton(),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: AppColors.lightPurple,
      appBar: isDesktop ? _buildDesktopAppBar() : _buildMobileAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }
}