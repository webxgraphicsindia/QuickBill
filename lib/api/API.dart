import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as _dio;
import 'package:intl/intl.dart';
import '../models/ApiResponse.dart';
import '../models/CartItem.dart';
import '../models/Customer.dart';
import '../models/Feedbackresponse.dart';
import '../models/ForgotResponse.dart';
import '../models/GetProfileResponse.dart';
import '../models/LoginResponse.dart';
import '../models/Product.dart';
import '../models/RegisterResponse.dart';
import '../models/TokenRefreshResponse.dart';
import '../models/TokenVerificationResponse.dart';
import '../models/Transaction.dart';
import '../models/TransactionSummary.dart';
import '../models/User.dart';

class apiServices {
  static const String _baseUrl = 'https://quickbillapi.quickbill.site/api';
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Helper method to get stored token
  static Future<String?> _getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Token Verification
  static Future<TokenVerificationResponse> verifyToken(String token) async {
    final url = Uri.parse('$_baseUrl/verify-token');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return TokenVerificationResponse(
          isValid: true,
          expiresSoon: responseData['expires_soon'] ?? false,
        );
      } else {
        return TokenVerificationResponse(
          isValid: false,
          message: responseData['message'] ?? 'Token verification failed',
        );
      }
    } catch (e) {
      return TokenVerificationResponse(
        isValid: false,
        message: 'Network error during token verification',
      );
    }
  }

  static Future<ApiResponse> verifyEmail({
    required String email,
    required String otp,
    required String? token,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/verify-email');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final body = jsonEncode({
      'email': email,
      'otp': otp,
      if (token != null) 'token': token,
    });

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = responseData['data']['token'];
        if (token != null) {
          await _storage.write(key: _tokenKey, value: token);
        }

        return ApiResponse(
          success: true,
          message: responseData['message'] ?? 'Email verified successfully',
        );
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Email verification failed',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error occurred during verification',
      );
    }
  }

  static Future<ApiResponse> resendVerificationOtp({
    required String email,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/resend-verification-otp');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final body = jsonEncode({
      'email': email,
    });

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: responseData['message'] ?? 'New OTP sent successfully',
        );
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to resend OTP',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error occurred while resending OTP',
      );
    }
  }

  static Future<RegisterResponse> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String? phone,
    String? companyName,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/register');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final body = jsonEncode({
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': confirmPassword,
      if (phone != null) 'mobile': phone,
      if (companyName != null) 'company_name': companyName,
    });

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      final responseData = jsonDecode(response.body);
      print("Register Response: $responseData");

      if (response.statusCode == 201 || response.statusCode == 200) {
        final token = responseData['data']['token'] ?? responseData['access_token'];

        return RegisterResponse(
          success: true,
          token: token,
          message: responseData['message'] ?? 'Registration successful. Please check your email for verification.',
        );
      } else {
        // Handle specific error cases
        String errorMessage = 'Registration failed';
        Map<String, dynamic>? errors;

        if (response.statusCode == 400) {
          errorMessage = 'Invalid data provided';
        } else if (response.statusCode == 409) {
          errorMessage = 'Email already registered';
          if (responseData['message']?.toLowerCase().contains('unverified') ?? false) {
            errorMessage = 'This email is registered but not verified. We have sent a new verification email.';
          }
        } else if (response.statusCode == 422) {
          errorMessage = 'Validation errors';
          errors = responseData['errors'];
          if (errors != null) {
            // Get the first error message from the validation errors
            errorMessage = errors.values.first.first ?? errorMessage;
          }
        }

        return RegisterResponse(
          success: false,
          message: responseData['message'] ?? errorMessage,
          errors: errors,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print("Registration Error: $e");
      String errorMessage = 'An unexpected error occurred';
      if (e is SocketException) {
        errorMessage = 'No internet connection';
      } else if (e is TimeoutException) {
        errorMessage = 'Connection timeout';
      }

      return RegisterResponse(
        success: false,
        message: errorMessage,
      );
    }
  }

  // Helper method for error messages
  static String _getErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request - invalid data provided';
      case 409:
        return 'Email already registered';
      case 422:
        return 'Validation failed for provided data';
      case 500:
        return 'Internal server error';
      default:
        return 'Registration failed with status code $statusCode';
    }
  }

  // Token Refresh
  static Future<TokenRefreshResponse> refreshToken(String refreshToken) async {
    final url = Uri.parse('$_baseUrl/refresh-token');
    final headers = {
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'refresh_token': refreshToken,
    });

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save new tokens to secure storage
        await _storage.write(key: _tokenKey, value: responseData['access_token']);
        await _storage.write(key: _refreshTokenKey, value: responseData['refresh_token']);

        return TokenRefreshResponse(
          success: true,
          accessToken: responseData['access_token'],
          refreshToken: responseData['refresh_token'],
        );
      } else {
        return TokenRefreshResponse(
          success: false,
          message: responseData['message'] ?? 'Token refresh failed',
        );
      }
    } catch (e) {
      return TokenRefreshResponse(
        success: false,
        message: 'Network error during token refresh',
      );
    }
  }

  // Login
  // In apiServices class, modify the login method:
  static Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final body = jsonEncode({
      'email': email,
      'password': password,
    });

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      final responseData = jsonDecode(response.body);
      print("Login Response: $responseData");

      if (response.statusCode == 200) {
        // Extract token from the nested data object
        final token = responseData['data']['token'];
        final userData = responseData['data']['user'];

        // Save token and user details to secure storage
        if (token != null) {
          await _storage.write(key: _tokenKey, value: token);
        }
        if (userData != null) {
          await _storage.write(key: 'user_details', value: jsonEncode(userData));
        }

        return LoginResponse(
          success: true,
          token: token,
          user: userData != null ? User.fromJson(userData) : null,
          message: responseData['message'] ?? 'Login successful',
        );
      } else {
        // Handle specific error cases
        String errorMessage = 'Login failed';
        if (response.statusCode == 401) {
          if (responseData['message']?.toLowerCase().contains('unverified') ?? false) {
            errorMessage = 'Your account is not verified. Please check your email for verification instructions.';
          } else {
            errorMessage = 'Invalid email or password';
          }
        } else if (response.statusCode == 403) {
          errorMessage = 'Account suspended. Please contact support.';
        } else if (response.statusCode == 422) {
          errorMessage = 'Validation error: ${responseData['errors']?.values.first?.first ?? 'Invalid data'}';
        } else if (response.statusCode == 429) {
          errorMessage = 'Too many login attempts. Please try again later.';
        }

        return LoginResponse(
          success: false,
          message: responseData['message'] ?? errorMessage,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print("Login Error: $e");
      String errorMessage = 'Network error occurred';
      if (e is SocketException) {
        errorMessage = 'No internet connection';
      } else if (e is TimeoutException) {
        errorMessage = 'Connection timeout';
      }

      return LoginResponse(
        success: false,
        message: errorMessage,
      );
    }
  }


  // Password Reset Methods
  static Future<Forgotresponse> sendPasswordResetOtp({
    required String email,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/forgot-password');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final body = jsonEncode({
      'email': email,
    });

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = responseData['data']['token'];
        return Forgotresponse(
          success: true,
          token: token,
          message: responseData['message'] ?? 'OTP sent successfully',
        );
      } else {
        return Forgotresponse(
          success: false,
          message: responseData['message'] ?? 'Failed to send OTP',
        );
      }
    } catch (e) {
      return Forgotresponse(
        success: false,
        message: 'Network error occurred',
      );
    }
  }

  static Future<Forgotresponse> verifyPasswordResetOtp({
    required String email,
    required String otp,
    required String accesstoken
  }) async {
    final url = Uri.parse('$_baseUrl/auth/verify-otp');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final body = jsonEncode({
      'email': email,
      'otp': otp,
      'token': accesstoken
    });

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      final responseData = jsonDecode(response.body);

      print(
        "Forgot response data {$responseData}"
      );
      if (response.statusCode == 200) {
        final token = responseData['data']['token'];
        return Forgotresponse(
          success: true,
          token: token,
          message: responseData['message'] ?? 'OTP verified successfully',
          data: responseData['reset_token'],
        );
      } else {
        return Forgotresponse(
          success: false,
          message: responseData['message'] ?? 'OTP verification failed',
        );
      }
    } catch (e) {
      return Forgotresponse(
        success: false,
        message: 'Network error occurred',
      );
    }
  }

  static Future<ApiResponse> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String password_confirmation,
    required String accesstoken
  }) async {
    final url = Uri.parse('$_baseUrl/auth/reset-password');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final body = jsonEncode({
      'email': email,
      'password': password,
      'password_confirmation': password_confirmation,
      'token': accesstoken
    });

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      final responseData = jsonDecode(response.body);

      print(
        "${responseData}"
      );
      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: responseData['message'] ?? 'Password reset successfully',
        );
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Password reset failed',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error occurred',
      );
    }
  }

  // Add these methods to your apiServices class

  static Future<ApiResponse<List<Customer>>> searchCustomers(String query) async {
    final token = await _getToken();
    if (token == null) {
      return ApiResponse(success: false, message: "Token not found");
    }

    final url = Uri.parse('$_baseUrl/customers?search=$query');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final customers = (responseData['data']['data'] as List)
            .map((customer) => Customer.fromJson(customer))
            .toList();
        return ApiResponse<List<Customer>>(
          success: true,
          data: customers,
          message: responseData['message'] ?? 'Customers fetched successfully',
        );
      } else {
        return ApiResponse<List<Customer>>(
          success: false,
          message: responseData['message'] ?? 'Failed to fetch customers',
        );
      }
    } catch (e) {
      print("Error searching customers: $e");
      return ApiResponse<List<Customer>>(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  static Future<ApiResponse<Customer>> createCustomer({
    required String name,
    required String mobile,
    String? address,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return ApiResponse(success: false, message: "Token not found");
    }

    final url = Uri.parse('$_baseUrl/customers');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'name': name,
      'mobile': mobile,
      if (address != null) 'address': address,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return ApiResponse<Customer>(
          success: true,
          data: Customer.fromJson(responseData['data']),
          message: responseData['message'] ?? 'Customer created successfully',
        );
      } else {
        return ApiResponse<Customer>(
          success: false,
          message: responseData['message'] ?? 'Failed to create customer',
        );
      }
    } catch (e) {
      return ApiResponse<Customer>(
        success: false,
        message: 'Error: $e',
      );
    }
  }


  static Future<ApiResponse<Feedbackresponse>> submitFeedback({
    required double rating,
    required String feedbackType,
    required String message,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return ApiResponse(success: false, message: "Token not found");
    }

    final url = Uri.parse('$_baseUrl/feedback/'); // Adjust the endpoint if needed
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'rating': rating,
      'feedback_type': feedbackType,
      'message': message,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiResponse<Feedbackresponse>(
          success: true,
          data: Feedbackresponse.fromJson(responseData['data']),
          message: responseData['message'] ?? 'Feedback submitted successfully',
        );
      } else {
        return ApiResponse<Feedbackresponse>(
          success: false,
          message: responseData['message'] ?? 'Failed to submit feedback',
        );
      }
    } catch (e) {
      return ApiResponse<Feedbackresponse>(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  static Future<ApiResponse<Feedbackresponse>> getUserFeedback() async {
    final token = await _getToken();
    if (token == null) {
      return ApiResponse(success: false, message: "Token not found");
    }

    final url = Uri.parse('$_baseUrl/feedback/');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);
      final responseData = jsonDecode(response.body);

      print("getUserFeedback ${responseData}");

      if (response.statusCode == 200) {
        // Handle single feedback object response
        if (responseData['data'] != null) {
          final feedback = Feedbackresponse.fromJson({
            'success': true,
            'message': responseData['message'],
            'rating': responseData['data']['rating'],
            'feedback_type': responseData['data']['feedback_type'],
            'message': responseData['data']['message'],
          });

          return ApiResponse<Feedbackresponse>(
            success: true,
            data: feedback,
            message: responseData['message'] ?? 'Feedback fetched successfully',
          );
        }
        return ApiResponse(success: false, message: 'No feedback data found');
      } else {
        return ApiResponse(success: false, message: responseData['message'] ?? 'Failed to fetch feedback');
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Error: $e');
    }
  }

  // Transaction Summary
  static Future<ApiResponse<TransactionSummary>> getTransactionSummary({DateTime? date}) async {
    final token = await _getToken();
    if (token == null) {
      return ApiResponse(
        success: false,
        message: 'No authentication token found',
      );
    }

    final url = Uri.parse('$_baseUrl/transactions/summary').replace(
      queryParameters: date != null ? {
        'date': DateFormat('yyyy-MM-dd').format(date),
      } : null,
    );
    print("Trasaction by date $url");
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(url, headers: headers);
      final responseData = jsonDecode(response.body);

      print("Transaction summary response: $responseData");

      if (response.statusCode == 200) {
        final summaryData = responseData['data'] ?? {};
        return ApiResponse<TransactionSummary>(
          success: true,
          data: TransactionSummary.fromJson(summaryData),
          message: responseData['message'] ?? 'Success',
        );
      } else {
        return ApiResponse<TransactionSummary>(
          success: false,
          message: responseData['message'] ?? 'Failed to load summary',
        );
      }
    } catch (e) {
      print("Error fetching transaction summary: $e");
      return ApiResponse<TransactionSummary>(
        success: false,
        message: 'Network error occurred',
      );
    }
  }

  // Logout
  static Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  static Future<GetProfileResponse> getProfile() async {
    final token = await _getToken();
    if (token == null) {
      return GetProfileResponse(success: false, message: "Token not found");
    }

    final url = Uri.parse('$_baseUrl/profile/');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final userData = responseData['data']['user'];
        if (userData != null) {
          // Update local storage with fresh data
          await _storage.write(key: 'user_details', value: jsonEncode(userData));

          return GetProfileResponse(
            success: true,
            user: User.fromJson(userData),
            message: responseData['message'] ?? 'Profile fetched successfully',
          );
        }
        return GetProfileResponse(
          success: true,
          message: responseData['message'] ?? 'Profile fetched successfully',
        );
      } else {
        return GetProfileResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to fetch profile',
        );
      }
    } catch (e) {
      return GetProfileResponse(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  static Future<GetProfileResponse> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String companyName,
    String? gstNumber,
    String? shopAddress,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return GetProfileResponse(success: false, message: "Token not found");
    }

    final url = Uri.parse('$_baseUrl/profile/update');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final body = jsonEncode({
      'name': name,
      'email': email,
      'mobile': phone,
      'Shopname': companyName,
      'gst_number': gstNumber,
      'shop_address': shopAddress,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final userData = responseData['data']['user'];
        if (userData != null) {
          await _storage.write(key: 'user_details', value: jsonEncode(userData));
          return GetProfileResponse(
            success: true,
            message: responseData['message'] ?? 'Profile updated successfully',
            user: User.fromJson(userData),
          );
        }
        return GetProfileResponse(
          success: true,
          message: responseData['message'] ?? 'Profile updated successfully',
        );
      } else {
        return GetProfileResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to update profile',
        );
      }
    } catch (e) {
      return GetProfileResponse(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  // lib/api/API.dart (add to existing API class)
  static Future<ApiResponse> getProducts() async {
    final token = await _getToken();
    if (token == null) {
      return ApiResponse(success: false, message: "Token not found");
    }

    final url = Uri.parse('$_baseUrl/products');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final products = (responseData['data'] as List)
            .map((product) => Product.fromJson(product))
            .toList();
        return ApiResponse(
          success: true,
          data: products,
          message: responseData['message'] ?? 'Products fetched successfully',
        );
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to fetch products',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  static Future<ApiResponse> createProduct(Map<String, dynamic> data) async {
    final token = await _getToken();
    if (token == null) {
      return ApiResponse(success: false, message: "Token not found");
    }

    final url = Uri.parse('$_baseUrl/products');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(data),
      );
      final responseData = jsonDecode(response.body);
print(
  "Response create $response"
);

      print(
        "$responseData  create product"
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiResponse(
          success: true,
          data: Product.fromJson(responseData['data']),
          message: responseData['message'] ?? 'Product created successfully',
        );
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to create product',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  static Future<ApiResponse> updateProduct(String id, Map<String, dynamic> data) async {
    final token = await _getToken();
    if (token == null) {
      return ApiResponse(success: false, message: "Token not found");
    }

    print("Updating product with ID: $id");
    print("Data being sent: $data");

    final url = Uri.parse('$_baseUrl/products/$id');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(data),
      );

      print("Update response status: ${response.statusCode}");
      print("Update response body: ${response.body}");

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          data: Product.fromJson(responseData['data']),
          message: responseData['message'] ?? 'Product updated successfully',
        );
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to update product',
        );
      }
    } catch (e) {
      print("Update error: $e");
      return ApiResponse(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  static Future<ApiResponse> deleteProduct(String id) async {
    final token = await _getToken();
    if (token == null) {
      return ApiResponse(success: false, message: "Token not found");
    }

    final url = Uri.parse('$_baseUrl/products/$id');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    try {
      final response = await http.delete(url, headers: headers);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: responseData['message'] ?? 'Product deleted successfully',
        );
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to delete product',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: $e',
      );
    }
  }


  //Transaction
  static Future<ApiResponse<List<Transaction>>> getTransactions() async {
    final token = await _getToken();
    if (token == null) {
      return ApiResponse(success: false, message: "Token not found");
    }

    final url = Uri.parse('$_baseUrl/transactions');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final transactions = (responseData['data'] as List)
            .map((txn) => Transaction.fromJson(txn))
            .toList();
        return ApiResponse<List<Transaction>>(
          success: true,
          data: transactions,
          message: responseData['message'] ?? 'Transactions fetched successfully',
        );
      } else {
        return ApiResponse<List<Transaction>>(
          success: false,
          message: responseData['message'] ?? 'Failed to fetch transactions',
        );
      }
    } catch (e) {
      return ApiResponse<List<Transaction>>(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  static Future<ApiResponse> completeTransaction(String transactionId) async {
    final token = await _getToken();
    if (token == null) {
      return ApiResponse(success: false, message: "Token not found");
    }

    final url = Uri.parse('$_baseUrl/transactions/$transactionId/complete');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.put(url, headers: headers);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: responseData['message'] ?? 'Transaction completed successfully',
        );
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to complete transaction',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  static Future<ApiResponse> deleteTransaction(String transactionId) async {
    final token = await _getToken();
    if (token == null) {
      return ApiResponse(success: false, message: "Token not found");
    }

    final url = Uri.parse('$_baseUrl/transactions/$transactionId');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    try {
      final response = await http.delete(url, headers: headers);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: responseData['message'] ?? 'Transaction deleted successfully',
        );
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to delete transaction',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: $e',
      );
    }
  }


  //Cart
  static Future<ApiResponse<List<CartItem>>> getCart() async {
    final token = await _getToken();
    if (token == null) {
      return ApiResponse(success: false, message: "Token not found");
    }

    final url = Uri.parse('$_baseUrl/cart');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);
      final responseData = jsonDecode(response.body);

      print(" cart ${responseData}");

      if (response.statusCode == 200) {
        final cartItems = (responseData['cart'] as List)
            .map((item) => CartItem.fromJson(item))
            .toList();
        return ApiResponse<List<CartItem>>(
          success: true,
          data: cartItems,
          message: responseData['message'] ?? 'Cart fetched successfully',
        );
      } else {
        return ApiResponse<List<CartItem>>(
          success: false,
          message: responseData['message'] ?? 'Failed to fetch cart',
        );
      }
    } catch (e) {
      return ApiResponse<List<CartItem>>(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  static Future<ApiResponse> addToCart(String productId, [int quantity = 1]) async {
    final token = await _getToken();
    if (token == null) {
      return ApiResponse(success: false, message: "Token not found");
    }

    final url = Uri.parse('$_baseUrl/cart/add');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'product_id': productId,
      'quantity': quantity,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: responseData['message'] ?? 'Product added to cart',
        );
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to add to cart',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  static Future<ApiResponse> removeFromCart(String productId) async {
    final token = await _getToken();
    if (token == null) {
      return ApiResponse(success: false, message: "Token not found");
    }

    final url = Uri.parse('$_baseUrl/cart/remove');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'product_id': productId,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: responseData['message'] ?? 'Product removed from cart',
        );
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to remove from cart',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  static Future<ApiResponse> clearCart() async {
    final token = await _getToken();
    if (token == null) {
      return ApiResponse(success: false, message: "Token not found");
    }

    final url = Uri.parse('$_baseUrl/cart/clear');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    try {
      final response = await http.post(url, headers: headers);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: responseData['message'] ?? 'Cart cleared',
        );
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to clear cart',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  static Future<ApiResponse> createTransaction({
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required double discount,
    required double finalAmount,
    required String paymentMode,
    String? customerId,
    String? customerMobile,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return ApiResponse(success: false, message: "Token not found");
    }

    final url = Uri.parse('$_baseUrl/transactions');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'items': items,
      'total_amount': totalAmount,
      'discount': discount,
      'final_amount': finalAmount,
      'payment_mode': paymentMode,
      if (customerId != null) 'customer_id': customerId,
      if (customerMobile != null) 'customer_mobile': customerMobile, // Add this line
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      final responseData = jsonDecode(response.body);

      print(
        "  Create Trasaction ${responseData}"
      );
      print(
        "reposne data create transaction ${response.body}"
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(
          success: true,
          message: responseData['message'] ?? 'Transaction created successfully',
        );
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to create transaction',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: $e',
      );
    }
  }


  static Future<ApiResponse<Product>> getProductByBarcode(String barcode) async {
    final token = await _getToken();
    if (token == null) {
      return ApiResponse(success: false, message: "Token not found");
    }

    final url = Uri.parse('$_baseUrl/products/barcode/$barcode');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse<Product>(
          success: true,
          data: Product.fromJson(responseData['data']),
          message: responseData['message'] ?? 'Product found',
        );
      } else {
        return ApiResponse<Product>(
          success: false,
          message: responseData['message'] ?? 'Product not found',
        );
      }
    } catch (e) {
      return ApiResponse<Product>(
        success: false,
        message: 'Error: $e',
      );
    }
  }
  Future<ApiResponse<List<dynamic>>> getExpenditures() async {
    final token = await _getToken();
    if (token == null) {
      return ApiResponse(success: false, message: "Token not found");
    }

    final url = Uri.parse('$_baseUrl/expenditures');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse<List<dynamic>>(
          success: true,
          data: responseData['data'],
          message: responseData['message'] ?? 'Expenditures fetched successfully',
        );
      } else {
        return ApiResponse<List<dynamic>>(
          success: false,
          message: responseData['message'] ?? 'Failed to fetch expenditures',
        );
      }
    } catch (e) {
      return ApiResponse<List<dynamic>>(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  Future<ApiResponse<dynamic>> createExpenditure(Map<String, dynamic> data) async {
    final token = await _getToken();
    if (token == null) {
      return ApiResponse(success: false, message: "Token not found");
    }

    final url = Uri.parse('$_baseUrl/expenditures');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(data),
      );
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return ApiResponse(
          success: true,
          data: responseData['data'],
          message: responseData['message'] ?? 'Expenditure created successfully',
        );
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to create expenditure',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  Future<ApiResponse<dynamic>> updateExpenditure(
      String id, Map<String, dynamic> data) async {
    final token = await _getToken();
    if (token == null) {
      return ApiResponse(success: false, message: "Token not found");
    }

    final url = Uri.parse('$_baseUrl/expenditures/$id');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(data),
      );
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          data: responseData['data'],
          message: responseData['message'] ?? 'Expenditure updated successfully',
        );
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to update expenditure',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  Future<ApiResponse> deleteExpenditure(String id) async {
    final token = await _getToken();
    if (token == null) {
      return ApiResponse(success: false, message: "Token not found");
    }

    final url = Uri.parse('$_baseUrl/expenditures/$id');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    try {
      final response = await http.delete(url, headers: headers);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: responseData['message'] ?? 'Expenditure deleted successfully',
        );
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to delete expenditure',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  Future<ApiResponse<List<dynamic>>> getExpenditureCategoryReport() async {
    final token = await _getToken();
    if (token == null) {
      return ApiResponse(success: false, message: "Token not found");
    }

    final url = Uri.parse('$_baseUrl/expenditures/report/category');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Convert amounts to double and calculate totals
        final data = (responseData['data'] as List).map((item) {
          return {
            'category': item['category'],
            'total': double.parse(item['total'].toString()),
          };
        }).toList();

        return ApiResponse<List<dynamic>>(
          success: true,
          data: data,
          message: responseData['message'] ?? 'Category report fetched successfully',
        );
      } else {
        return ApiResponse<List<dynamic>>(
          success: false,
          message: responseData['message'] ?? 'Failed to fetch category report',
        );
      }
    } catch (e) {
      return ApiResponse<List<dynamic>>(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  Future<ApiResponse<List<dynamic>>> getExpenditureDateRangeReport({
    required String startDate,
    required String endDate,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return ApiResponse(success: false, message: "Token not found");
    }

    final url = Uri.parse('$_baseUrl/expenditures/report/date-range')
        .replace(queryParameters: {
      'start_date': startDate,
      'end_date': endDate,
    });
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Convert amounts to double
        final data = (responseData['data'] as List).map((item) {
          return {
            ...item,
            'amount': double.parse(item['amount'].toString()),
          };
        }).toList();

        return ApiResponse<List<dynamic>>(
          success: true,
          data: data,
          message: responseData['message'] ?? 'Date range report fetched successfully',
        );
      } else {
        return ApiResponse<List<dynamic>>(
          success: false,
          message: responseData['message'] ?? 'Failed to fetch date range report',
        );
      }
    } catch (e) {
      return ApiResponse<List<dynamic>>(
        success: false,
        message: 'Error: $e',
      );
    }
  }
}