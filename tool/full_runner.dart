import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:shevchenko/shevchenko.dart';
import 'package:shevchenko/src/classifier.dart';

import '../test/fixtures/full.dart';
import 'fixture_validation.dart';

/// Also executable via dart2js/Node; corpus is embedded, with no filesystem IO.
Future<void> main() async {
  final corpus = jsonDecode(fullJson) as Map;
  validateFullCorpus(corpus.cast<String, Object?>());
  final rows = corpus['rows'] as List;
  final engine = Shevchenko();
  final classifier = FamilyNameClassifier();
  var maximumError = 0.0;
  final elapsed = Stopwatch()..start();
  for (final shard in corpus['shards'] as List) {
    final output = StringBuffer();
    final start = shard['start'] as int;
    for (final raw in rows.skip(start).take(shard['count'] as int)) {
      final row = raw as List;
      final word = row[0] as String;
      final reference = (row[1] as num).toDouble();
      final score = classifier.score(word);
      maximumError = math.max(maximumError, (score - reference).abs());
      if (!score.isFinite ||
          (score - reference).abs() > 1e-6 + 1e-5 * reference.abs() ||
          FamilyNameClassifier.decode(score) !=
              FamilyNameClassifier.decode(reference) ||
          classifier.classify(word).name != row[2]) {
        throw StateError(
          'Classifier mismatch: ${jsonEncode(word)} expected=$reference actual=$score',
        );
      }
      for (final gender in GrammaticalGender.values) {
        for (final grammaticalCase in GrammaticalCase.values) {
          final result = await engine.inflectRaw(grammaticalCase, {
            'gender': gender.name,
            'familyName': word,
          });
          output.writeln(jsonEncode(result));
        }
      }
    }
    final actual = sha256.convert(utf8.encode(output.toString())).toString();
    if (actual != shard['sha256']) {
      throw StateError('Full output mismatch in shard at $start: $actual');
    }
    if (start % 10000 == 0) {
      print('Verified ${start + (shard['count'] as int)} / ${rows.length}');
    }
  }
  print(
    jsonEncode({
      'status': 'passed',
      'uniqueWords': rows.length,
      'calls': corpus['calls'],
      'maximumScoreError': maximumError,
      'minimumMargin': corpus['minMargin'],
      'nearest': corpus['nearest'],
      'elapsedMilliseconds': elapsed.elapsedMilliseconds,
    }),
  );
}
