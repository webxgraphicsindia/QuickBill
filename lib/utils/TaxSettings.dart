// lib/utils/TaxSettings.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TaxSettings {
  static const _storage = FlutterSecureStorage();
  static const _taxBillingKey = 'tax_billing_enabled';

  static Future<bool> isTaxBillingEnabled() async {
    final value = await _storage.read(key: _taxBillingKey);
    return value == 'true';
  }

  static Future<void> setTaxBillingEnabled(bool enabled) async {
    await _storage.write(key: _taxBillingKey, value: enabled.toString());
  }
} 