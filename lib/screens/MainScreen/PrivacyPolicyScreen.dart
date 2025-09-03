import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'QuickBill Privacy Policy',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Last Updated: January 1, 2023',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 20),
            Text(
              '1. Information We Collect',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'We collect information you provide directly to us, such as when you create an account, including your name, email address, and other contact or identifying information.',
            ),
            SizedBox(height: 20),
            Text(
              '2. How We Use Your Information',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'We use the information we collect to provide, maintain, and improve our services, to develop new services, and to protect QuickBill and our users.',
            ),
            SizedBox(height: 20),
            Text(
              '3. Sharing of Information',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'We do not share your personal information with companies, organizations, or individuals outside of QuickBill except in the following cases: With your consent, for legal reasons, or with domain administrators.',
            ),
            SizedBox(height: 20),
            Text(
              '4. Security',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'We work hard to protect our users from unauthorized access to or unauthorized alteration, disclosure, or destruction of information we hold.',
            ),
            SizedBox(height: 20),
            Text(
              '5. Changes to This Policy',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'We may change this privacy policy from time to time. We will post any privacy policy changes on this page and, if the changes are significant, we will provide a more prominent notice.',
            ),
          ],
        ),
      ),
    );
  }
}