import 'dart:convert';

import 'package:shevchenko/shevchenko.dart';
import 'package:shevchenko/shevchenko_compat.dart' show Undefined;
import 'package:test/test.dart';

import '../fixtures/embedded.dart';

Object? decodeUndefined(Object? value) {
  if (value is Map) {
    if (value.length == 1 && value[r'$undefined'] == true) {
      return Undefined.value;
    }
    return value.map((k, v) => MapEntry(k as String, decodeUndefined(v)));
  }
  return value;
}

void main() {
  test('seeded mutations and explicit undefined tags match JS', () async {
    final engine = Shevchenko();
    for (final row in jsonDecode(mutationsJson) as List) {
      final op = (row['operation'] as String).substring(2);
      final grammaticalCase = GrammaticalCase.values.byName(
        op[0].toLowerCase() + op.substring(1),
      );
      final input = row['inputEncoding'] == null
          ? row['input']
          : decodeUndefined(row['input']);
      final expected = row['expected'] as Map;
      if (expected['kind'] == 'error') {
        await expectLater(
          engine.inflectRaw(grammaticalCase, input),
          throwsA(
            isA<InputValidationException>().having(
              (e) => e.message,
              'message',
              expected['message'],
            ),
          ),
          reason: row['id'] as String,
        );
      } else {
        expect(
          await engine.inflectRaw(grammaticalCase, input),
          expected['value'],
          reason: row['id'] as String,
        );
      }
    }
  });
}
