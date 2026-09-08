import 'dart:convert';

import 'package:test/test.dart';

import '../../tool/fixture_validation.dart';
import '../fixtures/full.dart';

void main() {
  late Map<String, Object?> corpus;
  setUpAll(() {
    corpus = (jsonDecode(fullJson) as Map).cast<String, Object?>();
  });
  test(
    'the recorded release corpus has complete unique row and shard coverage',
    () {
      expect(() => validateFullCorpus(corpus), returnsNormally);
    },
  );
  test('empty, missing, overlapping or corrupted shards cannot pass', () {
    final shards = corpus['shards'] as List;
    for (final broken in [
      [],
      shards.skip(1).toList(),
      [...shards, shards.last],
      [
        {...(shards.first as Map), 'sha256': 'invalid'},
        ...shards.skip(1),
      ],
    ]) {
      expect(
        () => validateFullCorpus({...corpus, 'shards': broken}),
        throwsStateError,
      );
    }
  });
  test('missing rows, duplicate words and invalid scores cannot pass', () {
    final rows = corpus['rows'] as List;
    expect(
      () => validateFullCorpus({...corpus, 'rows': rows.skip(1).toList()}),
      throwsStateError,
    );
    expect(
      () => validateFullCorpus({
        ...corpus,
        'rows': [rows[1], ...rows.skip(1)],
      }),
      throwsStateError,
    );
    expect(
      () => validateFullCorpus({
        ...corpus,
        'rows': [
          [(rows.first as List)[0], double.nan, 'noun'],
          ...rows.skip(1),
        ],
      }),
      throwsStateError,
    );
  });
}
