// Sanitizes user input to prevent XSS attacks.
// Entities built from unicode escapes so they survive source transport.
String sanitize(String input) {
  return input
      .replaceAll('\u0026', '\u0026amp;') // & → &amp;
      .replaceAll('\u003c', '\u0026lt;') // < → &lt;
      .replaceAll('\u003e', '\u0026gt;') // > → &gt;
      .replaceAll('\u0022', '\u0026quot;') // " → &quot;
      .replaceAll('\u0027', '\u0026#x27;'); // ' → &#x27;
}

/// Sanitizes and trims input
String sanitizeAndTrim(String input) {
  return sanitize(input.trim());
}

/// Validates email format
bool isValidEmail(String email) {
  return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}

/// Validates phone number — exactly 11 digits (Pakistan mobile: 03XXXXXXXXX).
bool isValidPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.length == 11;
}

/// Validates password strength
/// SEC-05: min 8 (Firebase Console password policy bhi 8 par set karo —
/// Authentication → Settings → Password policy).
bool isValidPassword(String password) {
  return password.length >= 8;
}
