import 'package:flutter/material.dart';
import 'package:quickbill/screens/MainScreen/DashboardScreen.dart';
import 'package:quickbill/screens/auth/ForgotPassword.dart';
import 'package:quickbill/screens/auth/LoginScreen.dart';
import 'package:quickbill/screens/auth/SignupScreen.dart';
import 'package:quickbill/screens/auth/SplashScreen.dart';
import 'package:quickbill/screens/MainScreen.dart';
import 'package:quickbill/screens/auth/VerifyEmailScreen.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickBill',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const SignupScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/MainScreen': (context) => const MainScreen(),
        '/verify-email': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return VerifyEmailScreen(
            email: args['email'],
            verificationToken: args['verificationToken'],
          );
        },
      },
      debugShowCheckedModeBanner: false,

    );
  }
}