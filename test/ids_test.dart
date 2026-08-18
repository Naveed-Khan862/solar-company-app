import 'package:flutter_test/flutter_test.dart';

import 'package:solar_company_project/utils/ids.dart';

void main() {
  test('generateId produces unique IDs (no collisions in 1000)', () {
    final ids = <String>{for (var i = 0; i < 1000; i++) generateId()};
    expect(ids.length, 1000);
  });

  test('generateId is not a bare timestamp (has random suffix)', () {
    final id = generateId();
    expect(id.contains('-'), isTrue);
    expect(id.length, greaterThan('1750000000000000'.length));
  });
}
