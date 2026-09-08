import 'dart:convert';

import 'package:test/test.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

import '../fixtures/unicode.dart';

void main() {
  test('Unicode 17 NFC conformance: all five columns', () {
    final rows = jsonDecode(unicodeJson) as List;
    expect(rows.length, greaterThan(19000));
    for (var i = 0; i < rows.length; i++) {
      final row = (rows[i] as List).cast<String>();
      for (var c = 0; c < 5; c++) {
        expect(
          unorm.nfc(row[c]),
          row[c < 3 ? 1 : 3],
          reason: 'Unicode row $i column $c',
        );
      }
    }
  });
}
