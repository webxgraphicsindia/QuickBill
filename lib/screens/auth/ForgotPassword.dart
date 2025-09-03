import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:quickbill/api/API.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 0; // 0: Email, 1: OTP, 2: New Password
  bool _isLoading = false;
  bool _showSuccessAnimation = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _token = "";

  // Color palette
  final Color primaryColor = const Color(0xFF6C63FF);
  final Color lightPurple = const Color(0xFFE6E6FA);
  final Color darkPurple = const Color(0xFF4A42D1);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _sendResetOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await apiServices.sendPasswordResetOtp(
        email: _emailController.text.trim(),
      );

      if (response.success) {
        _token = response.token ?? "";
        setState(() => _currentStep = 1);
        _showSuccessSnackbar('OTP sent to your email');
      } else {
        _showErrorSnackbar(response.message ?? 'Failed to send OTP');
      }
    } on PlatformException catch (e) {
      _showErrorSnackbar(e.message ?? 'An error occurred');
    } catch (e) {
      _showErrorSnackbar('An unexpected error occurred');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty || _otpController.text.length != 6) {
      _showErrorSnackbar('Please enter a valid 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await apiServices.verifyPasswordResetOtp(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
        accesstoken: _token,
      );

      if (response.success) {
        _token = response.token ?? "";
        setState(() => _currentStep = 2);
        _showSuccessSnackbar('OTP verified successfully');
      } else {
        _showErrorSnackbar(response.message ?? 'OTP verification failed');
      }
    } on PlatformException catch (e) {
      _showErrorSnackbar(e.message ?? 'An error occurred');
    } catch (e) {
      _showErrorSnackbar('An unexpected error occurred');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorSnackbar('Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _showSuccessAnimation = false;
    });

    try {
      final response = await apiServices.resetPassword(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
        password: _passwordController.text.trim(),
        password_confirmation: _confirmPasswordController.text.trim(),
        accesstoken: _token,
      );

      if (response.success) {
        _token = "";
        setState(() => _showSuccessAnimation = true);
        await Future.delayed(const Duration(seconds: 2));
        _showSuccessSnackbar('Password reset successfully!');
        Navigator.pop(context);
      } else {
        _showErrorSnackbar(response.message ?? 'Password reset failed');
      }
    } on PlatformException catch (e) {
      _showErrorSnackbar(e.message ?? 'An error occurred');
    } catch (e) {
      _showErrorSnackbar('An unexpected error occurred');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: Colors.red.shade700,
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: Colors.green.shade700,
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reset Password',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: darkPurple,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Enter your email to receive a verification code',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 30),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            hintText: 'Email',
            filled: true,
            fillColor: lightPurple.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.email, color: primaryColor),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendResetOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
            child: _isLoading
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
                : const Text(
              'SEND VERIFICATION CODE',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify OTP',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: darkPurple,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Enter the 6-digit code sent to ${_emailController.text}',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 30),
        TextFormField(
          controller: _otpController,
          decoration: InputDecoration(
            hintText: '6-digit OTP',
            filled: true,
            fillColor: lightPurple.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.lock_clock, color: primaryColor),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
            child: _isLoading
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
                : const Text(
              'VERIFY CODE',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () {
            setState(() => _currentStep = 0);
          },
          child: Text(
            'Change Email',
            style: TextStyle(
              color: primaryColor,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create New Password',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: darkPurple,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Create a strong new password for your account',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 30),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: 'New Password',
            filled: true,
            fillColor: lightPurple.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.lock, color: primaryColor),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade600,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a password';
            }
            if (value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            hintText: 'Confirm New Password',
            filled: true,
            fillColor: lightPurple.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade600,
              ),
              onPressed: () {
                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
              },
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
            child: _isLoading
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
                : const Text(
              'RESET PASSWORD',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: lightPurple,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Back button at the top
                  Padding(
                    padding: const EdgeInsets.only(left: 20, top: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: darkPurple),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Hero(
                          tag: 'app-logo',
                          child: Material(
                            type: MaterialType.transparency,
                            child: Image.asset(
                              'lib/assets/images/Quickbilllogo.png',
                              height: 70,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'QuickBill',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: darkPurple,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!_showSuccessAnimation)
                    Lottie.asset(
                      'lib/assets/LottieFies/forgot_password.json',
                      height: 150,
                      repeat: true,
                      fit: BoxFit.contain,
                    ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, -10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Step indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(3, (index) {
                              return Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: _currentStep >= index
                                          ? primaryColor
                                          : Colors.grey.shade300,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: _currentStep >= index
                                              ? Colors.white
                                              : Colors.grey.shade600,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (index < 2)
                                    Container(
                                      width: 40,
                                      height: 2,
                                      color: _currentStep > index
                                          ? primaryColor
                                          : Colors.grey.shade300,
                                    ),
                                ],
                              );
                            }),
                          ),
                          const SizedBox(height: 30),
                          // Current step content
                          if (_currentStep == 0) _buildEmailStep(),
                          if (_currentStep == 1) _buildOtpStep(),
                          if (_currentStep == 2) _buildPasswordStep(),
                          const SizedBox(height: 20),
                          // Footer
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  "🇮🇳 Made with ❤️ for businesses",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "QuickBill • Simplify Your Billing",
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Success animation overlay
          if (_showSuccessAnimation)
            Container(
              color: Colors.white.withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'lib/assets/LottieFies/successfull.json',
                      width: 200,
                      height: 200,
                      repeat: false,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Password Reset Successful!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: lightPurple,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 1200,
                    minHeight: 700, // Ensure minimum height
                  ),
                  padding: const EdgeInsets.all(40),
                  child: Row(
                    children: [
                      // Left side - Illustration and info
                      Expanded(
                        flex: 5,
                        child: Stack(
                          children: [
                            Positioned(
                              top: 20,
                              left: 0,
                              child: IconButton(
                                icon: Icon(Icons.arrow_back,
                                    color: darkPurple,
                                    size: 30),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            Center(
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Hero(
                                      tag: 'app-logo',
                                      child: Material(
                                        type: MaterialType.transparency,
                                        child: Image.asset(
                                          'lib/assets/images/Quickbilllogo.png',
                                          height: 100,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'QuickBill',
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: darkPurple,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 30),
                                    if (!_showSuccessAnimation)
                                      SizedBox(
                                        height: 300,
                                        child: Lottie.asset(
                                          'lib/assets/LottieFies/forgot_password.json',
                                          repeat: true,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    const SizedBox(height: 30),
                                    Text(
                                      'Secure Password Recovery',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                        color: darkPurple,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 40),
                                      child: Text(
                                        'Follow the simple steps to reset your password and regain access to your account.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 60),
                      // Right side - Form
                      Expanded(
                        flex: 4,
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Step indicator
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(3, (index) {
                                      return Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: _currentStep >= index
                                                  ? primaryColor
                                                  : Colors.grey.shade300,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${index + 1}',
                                                style: TextStyle(
                                                  color: _currentStep >= index
                                                      ? Colors.white
                                                      : Colors.grey.shade600,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (index < 2)
                                            Container(
                                              width: 60,
                                              height: 2,
                                              color: _currentStep > index
                                                  ? primaryColor
                                                  : Colors.grey.shade300,
                                            ),
                                        ],
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 40),
                                  // Current step content
                                  if (_currentStep == 0) _buildEmailStep(),
                                  if (_currentStep == 1) _buildOtpStep(),
                                  if (_currentStep == 2) _buildPasswordStep(),
                                  const SizedBox(height: 30),
                                  // Footer
                                  Center(
                                    child: Column(
                                      children: [
                                        Text(
                                          "🇮🇳 Made with ❤️ for businesses",
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          "QuickBill • Simplify Your Billing",
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Success animation overlay
          if (_showSuccessAnimation)
            Container(
              color: Colors.white.withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'lib/assets/LottieFies/successfull.json',
                      width: 300,
                      height: 300,
                      repeat: false,
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Password Reset Successful!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: darkPurple,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'BACK TO LOGIN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return _buildDesktopLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }
}