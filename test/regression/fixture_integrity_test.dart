import 'dart:convert';

import 'package:test/test.dart';

import '../fixtures/embedded.dart';

const _provenance = 'core-e99c64c-military-5b2d748-tfjs-cpu-4.22.0';
const _operations = {
  'inNominative',
  'inGenitive',
  'inDative',
  'inAccusative',
  'inAblative',
  'inLocative',
  'inVocative',
  'detectGender',
};
const _cases = {
  'nominative',
  'genitive',
  'dative',
  'accusative',
  'ablative',
  'locative',
  'vocative',
};

void main() {
  test('golden corpus keeps its exact independent oracle coverage', () {
    final rows = jsonDecode(goldenJson) as List;
    expect(rows, hasLength(9797));
    final ids = <String>{};
    final counts = <String, int>{};
    for (final raw in rows) {
      final row = raw as Map;
      expect(row['schemaVersion'], 1);
      expect(row['origin'], 'combined-upstream-oracle');
      expect(row['provenanceId'], _provenance);
      expect(ids.add(row['id'] as String), isTrue, reason: '${row['id']}');
      final operation = row['operation'] as String;
      expect(_operations, contains(operation), reason: row['id'] as String);
      counts.update(operation, (value) => value + 1, ifAbsent: () => 1);
      final expected = row['expected'] as Map;
      expect({'value', 'error'}, contains(expected['kind']));
      if (expected['kind'] == 'value') {
        expect(expected, contains('value'));
      } else {
        expect(expected['message'], isA<String>());
      }
    }
    expect(counts, {
      'inNominative': 1232,
      'inGenitive': 1244,
      'inDative': 1232,
      'inAccusative': 1232,
      'inAblative': 1232,
      'inLocative': 1232,
      'inVocative': 1232,
      'detectGender': 1161,
    });
  });

  test('mutation corpus cannot silently lose cases or records', () {
    final rows = jsonDecode(mutationsJson) as List;
    expect(rows, hasLength(1029));
    final ids = <String>{};
    final operations = <String>{};
    for (final raw in rows) {
      final row = raw as Map;
      expect(row['provenanceId'], _provenance);
      expect(ids.add(row['id'] as String), isTrue, reason: '${row['id']}');
      operations.add(row['operation'] as String);
      expect({'value', 'error'}, contains((row['expected'] as Map)['kind']));
    }
    expect(operations, _operations.difference({'detectGender'}));
  });

  test('classifier and recurrent-state fixtures retain full dimensions', () {
    final classifier = jsonDecode(classifierJson) as List;
    expect(classifier, hasLength(1175));
    expect(
      classifier.map((row) => (row as Map)['word']).toSet(),
      hasLength(1175),
    );
    for (final raw in classifier) {
      final row = raw as Map;
      expect(row['vector'], isA<List>().having((v) => v.length, 'length', 20));
      expect((row['score'] as num).isFinite, isTrue);
      expect({'noun', 'adjective'}, contains(row['rawClass']));
      expect({'noun', 'adjective'}, contains(row['effectiveClass']));
    }

    final layers = jsonDecode(layersJson) as List;
    expect(layers, hasLength(28));
    expect(layers.map((row) => (row as Map)['word']).toSet(), hasLength(28));
    for (final raw in layers) {
      final row = raw as Map;
      expect(
        row['embedding'],
        isA<List>().having((v) => v.length, 'length', 320),
      );
      final states = row['states'] as List;
      expect(states, hasLength(20));
      expect(states.every((state) => (state as List).length == 16), isTrue);
      expect((row['score'] as num).isFinite, isTrue);
    }
  });

  test('isolated-rule corpus covers every rule and every case', () {
    final rows = jsonDecode(rulesJson) as List;
    expect(rows, hasLength(924));
    final casesByRule = <int, Set<String>>{};
    for (final raw in rows) {
      final row = raw as Map;
      final index = row['index'] as int;
      expect(index, inInclusiveRange(0, 98));
      expect(row['word'], isA<String>());
      expect(row['result'], isA<String>());
      final params = row['params'] as Map;
      final grammaticalCase = params['grammaticalCase'] as String;
      expect(_cases, contains(grammaticalCase));
      expect({'masculine', 'feminine'}, contains(params['gender']));
      casesByRule.putIfAbsent(index, () => <String>{}).add(grammaticalCase);
    }
    expect(
      casesByRule.keys.toSet(),
      Set<int>.from(List.generate(99, (i) => i)),
    );
    for (final entry in casesByRule.entries) {
      expect(entry.value, _cases, reason: 'rule ${entry.key}');
    }
  });
}
