import 'dart:math';

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';

class SplashScreenWithBarcode extends StatefulWidget {
  const SplashScreenWithBarcode({Key? key}) : super(key: key);

  @override
  _SplashScreenWithBarcodeState createState() => _SplashScreenWithBarcodeState();
}

class _SplashScreenWithBarcodeState extends State<SplashScreenWithBarcode> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _barcodeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _barcodeAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: const Offset(0, 1),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade800,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 200,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white54, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CustomPaint(
                      painter: BarcodeBackgroundPainter(),
                    ),
                  ),
                ),
                SlideTransition(
                  position: _barcodeAnimation,
                  child: Container(
                    width: 180,
                    height: 4,
                    color: Colors.greenAccent.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            const Text(
              'QuickBill',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Scan. Bill. Done.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BarcodeBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.0;

    final rng = Random();
    for (double i = 0; i < size.width; i += 4) {
      final lineHeight = rng.nextDouble() * size.height;
      canvas.drawLine(
        Offset(i, size.height / 2 - lineHeight / 2),
        Offset(i, size.height / 2 + lineHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}