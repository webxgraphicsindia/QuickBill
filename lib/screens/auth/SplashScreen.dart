import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final _storage = const FlutterSecureStorage();
  bool _permissionsGranted = false;
  bool _showingPermissionDialog = false;
  String _permissionStatus = 'Checking permissions...';

  // Color scheme
  final Color _primaryColor = const Color(0xFF6C63FF);
  final Color _darkBlue = const Color(0xFF4A42D1);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Check permissions first, then auth status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissions();
    });
  }

  Future<void> _checkPermissions() async {
    setState(() => _permissionStatus = 'Checking permissions...');

    // First check current permission statusz
    final cameraStatus = await Permission.camera.status;

    if (cameraStatus.isGranted) {
      _handlePermissionsGranted();
      return;
    }

    // Check if we should show rationale
    final shouldShowRationale = await Permission.camera.shouldShowRequestRationale;

    if (shouldShowRationale && !_showingPermissionDialog) {
      _showPermissionRationale();
      return;
    }

    // Request camera permission
    final permissionResult = await Permission.camera.request();

    if (permissionResult.isGranted) {
      _handlePermissionsGranted();
    } else {
      setState(() => _permissionStatus = 'Camera permission required');
      if (!_showingPermissionDialog) {
        _showPermissionDeniedDialog();
      }
    }
  }

  void _handlePermissionsGranted() {
    setState(() {
      _permissionsGranted = true;
      _permissionStatus = 'Permissions granted!';
    });
    _checkAuthStatus();
  }

  void _showPermissionRationale() {
    setState(() => _showingPermissionDialog = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Needed'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('QuickBill needs camera access to:'),
            SizedBox(height: 8),
            Text('🔹 Scan product barcodes'),
            Text('🔹 Quickly add items to cart'),
            SizedBox(height: 16),
            Text('Without this feature, you would need to manually enter product codes.'),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Deny'),
            onPressed: () {
              Navigator.of(context).pop();
              _showPermissionDeniedDialog();
            },
          ),
          TextButton(
            child: const Text('Allow'),
            onPressed: () {
              Navigator.of(context).pop();
              _checkPermissions(); // Try requesting again
            },
          ),
        ],
      ),
    ).then((_) => setState(() => _showingPermissionDialog = false));
  }

  void _showPermissionDeniedDialog() {
    setState(() => _showingPermissionDialog = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('The barcode scanner feature requires camera access.'),
            SizedBox(height: 16),
            Text('You can enable it in:'),
            Text('Settings > Apps > QuickBill > Permissions'),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Exit App'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Open Settings'),
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings().then((_) {
                // Check again after returning from settings
                Future.delayed(const Duration(seconds: 1), _checkPermissions);
              });
            },
          ),
        ],
      ),
    ).then((_) => setState(() => _showingPermissionDialog = false));
  }

  Future<void> _checkAuthStatus() async {
    setState(() => _permissionStatus = 'Checking login status...');

    try {
      final token = await _storage.read(key: 'access_token');
      if (token != null && token.isNotEmpty) {
        Navigator.pushReplacementNamed(context, '/MainScreen');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      setState(() => _permissionStatus = 'Error checking login');
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _animation,
              child: Image.asset(
                'lib/assets/images/Quickbilllogo.png',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'QuickBill',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 4,
                    color: _darkBlue.withOpacity(0.5),
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Smart Billing Solution',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              _permissionStatus,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  backgroundColor: _darkBlue,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8),
                  ),
                  minHeight: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}