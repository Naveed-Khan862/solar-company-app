import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// For fingerprint login the email+password live in the device's encrypted
/// keystore — never in plaintext shared_preferences.
/// Note: encryptedSharedPreferences (Jetpack) fails on Android 13+, so the
/// default keystore encryption is the reliable option.
class SecureCredentials {
  SecureCredentials._();

static const _storage = FlutterSecureStorage();
  static const _emailKey = 'fp_email';
  static const _passwordKey = 'fp_password';

  static Future<void> save(String email, String password) async {
    // SEC-07: no PII (email) in logs — the email must not reach release logs.
    await _storage.write(key: _emailKey, value: email.toLowerCase());
    await _storage.write(key: _passwordKey, value: password);
  }

  static Future<({String email, String password})?> read() async {
    final email = await _storage.read(key: _emailKey);
    final password = await _storage.read(key: _passwordKey);
    // SEC-07: log presence only — the email value is never logged.
    if (email == null || password == null) return null;
    return (email: email, password: password);
  }

  static Future<void> clear() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
  }
}
