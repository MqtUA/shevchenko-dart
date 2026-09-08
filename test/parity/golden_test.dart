import 'dart:convert';

import 'package:shevchenko/shevchenko.dart';
import 'package:shevchenko/src/classifier.dart';
import 'package:test/test.dart';

import '../fixtures/embedded.dart';

void main() {
  final engine = Shevchenko();
  final golden = jsonDecode(goldenJson) as List;
  for (var start = 0; start < golden.length; start += 250) {
    final batch = golden.skip(start).take(250).toList();
    test(
      'whole-output oracle records $start..${start + batch.length - 1}',
      () async {
        for (final raw in batch) {
          final fixture = raw as Map;
          final expected = fixture['expected'] as Map;
          final operation = fixture['operation'] as String;
          Future<Object?> invoke() async {
            if (operation == 'detectGender') {
              return (await engine.detectGenderRaw(fixture['input']))?.name;
            }
            final name = operation.substring(2);
            return engine.inflectRaw(
              GrammaticalCase.values.byName(
                name[0].toLowerCase() + name.substring(1),
              ),
              fixture['input'],
            );
          }

          if (expected['kind'] == 'error') {
            await expectLater(
              invoke,
              throwsA(
                isA<InputValidationException>().having(
                  (e) => e.message,
                  'message',
                  expected['message'],
                ),
              ),
              reason: fixture['id'] as String,
            );
          } else {
            expect(
              await invoke(),
              expected['value'],
              reason: fixture['id'] as String,
            );
          }
        }
      },
    );
  }
  test('encoder, raw model score/class and every frozen override', () {
    final classifier = FamilyNameClassifier();
    for (final row in jsonDecode(classifierJson) as List) {
      final word = row['word'] as String;
      expect(classifier.encode(word), row['vector'], reason: word);
      final score = classifier.score(word);
      expect(
        score,
        closeTo(row['score'] as num, 1e-6 + 1e-5 * (row['score'] as num).abs()),
        reason: word,
      );
      expect(
        FamilyNameClassifier.decode(score).name,
        row['rawClass'],
        reason: word,
      );
      expect(
        classifier.classify(word).name,
        row['effectiveClass'],
        reason: word,
      );
    }
  });
  test('all 20 recurrent states match actual TensorFlow cells', () {
    final classifier = FamilyNameClassifier();
    for (final row in jsonDecode(layersJson) as List) {
      final states = <List<double>>[];
      final word = row['word'] as String;
      classifier.score(word, states: states);
      for (var t = 0; t < 20; t++) {
        for (var i = 0; i < 16; i++) {
          final reference = row['states'][t][i] as num;
          expect(
            states[t][i],
            closeTo(reference, 1e-6 + 1e-5 * reference.abs()),
            reason: '$word state=$t unit=$i',
          );
        }
      }
    }
  });
}
