import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:quickbill/api/API.dart';
import '../../constants/Colors.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final String? verificationToken;

  const VerifyEmailScreen({
    Key? key,
    required this.email,
    this.verificationToken,
  }) : super(key: key);

  @override
  _VerifyEmailScreenState createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>  with SingleTickerProviderStateMixin
{
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _resendLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade700,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(10),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade700,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(10),
      ),
    );
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty || _otpController.text.length != 6) {
      _showErrorSnackbar('Please enter a valid 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await apiServices.verifyEmail(
        email: widget.email,
        otp: _otpController.text,
        token: widget.verificationToken,
      );

      if (response.success) {
        _showSuccessSnackbar('Email verified successfully!');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showErrorSnackbar(response.message ?? 'OTP verification failed');
      }
    } catch (e) {
      _showErrorSnackbar('An error occurred during verification');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _resendLoading = true);

    try {
      final response = await apiServices.resendVerificationOtp(
        email: widget.email,
      );

      if (response.success) {
        _showSuccessSnackbar('New OTP sent to your email');
      } else {
        _showErrorSnackbar(response.message ?? 'Failed to resend OTP');
      }
    } catch (e) {
      _showErrorSnackbar('An error occurred while resending OTP');
    } finally {
      setState(() => _resendLoading = false);
    }
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: AppColors.lightPurple,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: AppColors.darkPurple),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
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
                          height: 80,
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
                        color: AppColors.darkPurple,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verify Your Email',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkPurple,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'We sent a 6-digit code to ${widget.email}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter 6-digit OTP',
                        filled: true,
                        fillColor: AppColors.lightPurple.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.lock_clock, color: AppColors.primaryColor),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      maxLength: 6,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
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
                          'VERIFY EMAIL',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: _resendLoading ? null : _resendOtp,
                        child: _resendLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          'Resend OTP',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: AppColors.lightPurple,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.all(40),
          child: Row(
            children: [
              // Left side - Illustration
              Expanded(
                flex: 5,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back,
                              color: AppColors.darkPurple,
                              size: 30),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
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
                          color: AppColors.darkPurple,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Lottie.asset(
                        'lib/assets/LottieFies/email_verification.json',
                        height: 350,
                        repeat: true,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'Email Verification',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkPurple,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Enter the verification code sent to your email address',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Verify Your Email',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkPurple,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'We sent a 6-digit code to ${widget.email}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 30),
                        TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter 6-digit OTP',
                            filled: true,
                            fillColor: AppColors.lightPurple.withOpacity(0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(Icons.lock_clock, color: AppColors.primaryColor),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          maxLength: 6,
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _verifyOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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
                              'VERIFY EMAIL',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: TextButton(
                            onPressed: _resendLoading ? null : _resendOtp,
                            child: _resendLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                                : Text(
                              'Resend OTP',
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
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
            ],
          ),
        ),
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