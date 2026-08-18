import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Fingerprint login ke liye email+password device ke encrypted keystore
/// mein — plaintext shared_preferences kabhi nahi.
/// Note: encryptedSharedPreferences (Jetpack) Android 13+ par fail karta
/// hai — default keystore-encryption reliable hai.
class SecureCredentials {
  SecureCredentials._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: false),
  );
  static const _emailKey = 'fp_email';
  static const _passwordKey = 'fp_password';

  static Future<void> save(String email, String password) async {
    // SEC-07: logs mein koi PII (email) nahi — release logs mein email na aaye.
    debugPrint('SecureCredentials: saving credentials');
    await _storage.write(key: _emailKey, value: email.toLowerCase());
    await _storage.write(key: _passwordKey, value: password);
    debugPrint('SecureCredentials: saved');
  }

  static Future<({String email, String password})?> read() async {
    final email = await _storage.read(key: _emailKey);
    final password = await _storage.read(key: _passwordKey);
    // SEC-07: sirf presence log — email value kabhi log nahi hoti.
    debugPrint('SecureCredentials: read ${email == null ? 'missing' : 'found'}');
    if (email == null || password == null) return null;
    return (email: email, password: password);
  }

  static Future<void> clear() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
    debugPrint('SecureCredentials: cleared');
  }
}
