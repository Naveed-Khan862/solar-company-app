import 'package:flutter_test/flutter_test.dart';

import 'package:solar_company_project/utils/input_sanitizer.dart';

void main() {
  group('sanitize', () {
    test('escapes angle brackets', () {
      expect(sanitize('<script>'), '&lt;script&gt;');
    });

    test('escapes ampersand', () {
      expect(sanitize('a&b'), 'a&amp;b');
    });

    test('escapes quotes', () {
      expect(sanitize('"q"'), '&quot;q&quot;');
      expect(sanitize("it's"), 'it&#x27;s');
    });
  });

  group('sanitizeAndTrim', () {
    test('trims whitespace', () {
      expect(sanitizeAndTrim('  hello  '), 'hello');
    });
  });

  group('isValidEmail', () {
    test('accepts valid emails', () {
      expect(isValidEmail('user@company.com'), isTrue);
      expect(isValidEmail('a.b-c@x.io'), isTrue);
    });

    test('rejects invalid emails', () {
      expect(isValidEmail('not-an-email'), isFalse);
      expect(isValidEmail('a@b'), isFalse);
      expect(isValidEmail(''), isFalse);
    });
  });

  group('isValidPhone', () {
    test('accepts exactly 11 digits', () {
      expect(isValidPhone('0300-1234567'), isTrue);
      expect(isValidPhone('03001234567'), isTrue);
    });

    test('rejects not-exactly-11-digit numbers', () {
      expect(isValidPhone('+923001234567'), isFalse);
      expect(isValidPhone('123'), isFalse);
      expect(isValidPhone('0300123456'), isFalse);
    });
  });

  group('isValidPassword', () {
    test('requires at least 8 characters (SEC-05)', () {
      expect(isValidPassword('12345678'), isTrue);
      expect(isValidPassword('1234567'), isFalse);
      expect(isValidPassword('12345'), isFalse);
    });
  });
}
