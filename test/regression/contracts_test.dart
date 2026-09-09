import 'dart:convert';

import 'package:shevchenko/shevchenko.dart';
import 'package:shevchenko/shevchenko_compat.dart' as compat;
import 'package:shevchenko/src/generated/data.dart';
import 'package:test/test.dart';

import '../fixtures/embedded.dart';

DeclensionRule custom(
  String modify, {
  String find = '',
  String value = 'x',
  InflectionCommandAction action = InflectionCommandAction.replace,
  int priority = 1,
  List<ApplicationType> applications = const [],
}) => DeclensionRule(
  wordClass: WordClass.noun,
  gender: GrammaticalGender.values,
  priority: priority,
  applicationType: applications,
  pattern: DeclensionPattern(find: find, modify: modify),
  grammaticalCases: {
    for (final c in GrammaticalCase.values)
      c: [
        {0: InflectionCommand(action: action, value: value)},
      ],
  },
);
const params = DeclensionParams(
  grammaticalCase: GrammaticalCase.genitive,
  gender: GrammaticalGender.masculine,
);

void main() {
  test('DTO const constructors, nested ownership and structural equality', () {
    const output = DeclensionOutput(givenName: 'Тараса');
    expect(output, DeclensionOutput.fromJson({'givenName': 'Тараса'}));
    expect(
      output.hashCode,
      DeclensionOutput.fromJson({'givenName': 'Тараса'}).hashCode,
    );
    final nested = <Object?>['one'];
    final input = DeclensionInput.withCustomFields(
      gender: GrammaticalGender.masculine,
      customFields: {
        'extra': {'list': nested},
      },
    );
    nested[0] = 'two';
    final frozen = (input.customFields['extra'] as Map)['list'] as List;
    expect(frozen, ['one']);
    expect(() => frozen.add('three'), throwsUnsupportedError);
    final equal = DeclensionInput.withCustomFields(
      gender: GrammaticalGender.masculine,
      customFields: {
        'extra': {
          'list': ['one'],
        },
      },
    );
    expect(input, equal);
    expect(input.hashCode, equal.hashCode);
  });
  test(
    'all top-level, instance and map case methods select the right case',
    () async {
      final instance = Shevchenko();
      final top = [
        inNominative,
        inGenitive,
        inDative,
        inAccusative,
        inAblative,
        inLocative,
        inVocative,
      ];
      final methods = [
        instance.inNominative,
        instance.inGenitive,
        instance.inDative,
        instance.inAccusative,
        instance.inAblative,
        instance.inLocative,
        instance.inVocative,
      ];
      final raw = [
        compat.inNominative,
        compat.inGenitive,
        compat.inDative,
        compat.inAccusative,
        compat.inAblative,
        compat.inLocative,
        compat.inVocative,
      ];
      const input = DeclensionInput(
        gender: GrammaticalGender.feminine,
        givenName: 'Оксана',
      );
      final json = input.toJson();
      const expected = [
        {'givenName': 'Оксана'},
        {'givenName': 'Оксани'},
        {'givenName': 'Оксані'},
        {'givenName': 'Оксану'},
        {'givenName': 'Оксаною'},
        {'givenName': 'Оксані'},
        {'givenName': 'Оксано'},
      ];
      for (var i = 0; i < 7; i++) {
        expect((await top[i](input)).toJson(), expected[i]);
        expect((await methods[i](input)).toJson(), expected[i]);
        expect(await raw[i](json), expected[i]);
      }
      expect(
        await detectGender(const GenderDetectionInput(givenName: 'Оксана')),
        GrammaticalGender.feminine,
      );
      expect(await compat.detectGender({'givenName': 'Оксана'}), 'feminine');
    },
  );
  test('all 99 isolated rules and every case match upstream', () async {
    final covered = <int>{};
    for (final row in jsonDecode(rulesJson) as List) {
      final index = row['index'] as int;
      covered.add(index);
      final input = row['params'] as Map;
      final output = await WordInflector([defaultRules[index]]).inflect(
        row['word'] as String,
        DeclensionParams(
          grammaticalCase: GrammaticalCase.values.byName(
            input['grammaticalCase'] as String,
          ),
          gender: GrammaticalGender.values.byName(input['gender'] as String),
        ),
      );
      expect(output, row['result'], reason: 'rule $index ${row['word']}');
    }
    expect(covered.length, 99);
  });
  test(
    'equal priorities preserve source order; filter sees every candidate',
    () async {
      final first = custom('(.*)', value: 'first');
      final second = custom('(.*)', value: 'second');
      final engine = WordInflector([
        first,
        second,
        custom('(.*)', find: 'nomatch', priority: 2),
      ]);
      final calls = <int>[];
      final result = await engine.inflect(
        'a',
        DeclensionParams(
          grammaticalCase: params.grammaticalCase,
          gender: params.gender,
          customRuleFilter: (rule, index, rules) {
            expect(rules, [first, second]);
            calls.add(index);
            return index == 0;
          },
        ),
      );
      // Global (.*) also matches the empty suffix.
      expect(result, 'firstfirst');
      expect(calls, [0, 1]);
    },
  );
  test(
    'optional groups, zero-width matches and no captures retain JS semantics',
    () async {
      expect(
        await WordInflector([
          custom('(a)?(b)', action: InflectionCommandAction.append),
        ]).inflect('b', params),
        'undefinedxb',
      );
      expect(await WordInflector([custom('(?:a)')]).inflect('a', params), '');
      expect(
        await WordInflector([
          custom('(?=(a))', value: 'q'),
        ]).inflect('aa', params),
        'qaqa',
      );
      expect(
        await WordInflector([custom('(a)', value: r'$1')]).inflect('a', params),
        r'$1',
      );
    },
  );
  test(
    'only first command alternative executes; data and caller list are immutable',
    () async {
      final rule = DeclensionRule(
        wordClass: WordClass.noun,
        gender: GrammaticalGender.values,
        priority: 1,
        pattern: const DeclensionPattern(find: '', modify: '(a)'),
        grammaticalCases: {
          for (final c in GrammaticalCase.values)
            c: [
              {
                0: const InflectionCommand(
                  action: InflectionCommandAction.replace,
                  value: 'b',
                ),
              },
              {
                0: const InflectionCommand(
                  action: InflectionCommandAction.replace,
                  value: 'c',
                ),
              },
            ],
        },
      );
      final list = [rule];
      final engine = WordInflector(list);
      list.clear();
      expect(await engine.inflect('a', params), 'b');
      expect(() => rule.gender.clear(), throwsUnsupportedError);
      expect(() => rule.grammaticalCases.clear(), throwsUnsupportedError);
    },
  );
  test(
    'extensions receive normalized input; sequential order and last-write merge',
    () async {
      final engine = Shevchenko.core();
      final events = <String>[];
      engine.registerExtension(
        (context) => ShevchenkoExtension(
          fieldNames: ['custom'],
          afterInflect: (c, input) async {
            events.add('start');
            await Future<void>.delayed(Duration.zero);
            expect(input['givenName'], 'Йосип');
            expect(input['extra'], 'И\u0306');
            expect(
              () => input['givenName'] = 'changed',
              throwsUnsupportedError,
            );
            events.add('end');
            return {'givenName': 'override', 'custom': 'first'};
          },
        ),
      );
      engine.registerExtension(
        (context) => ShevchenkoExtension(
          fieldNames: [],
          afterInflect: (c, input) {
            events.add('second');
            return {'custom': 'last'};
          },
        ),
      );
      final input = {
        'gender': 'masculine',
        'givenName': 'И\u0306осип',
        'extra': 'И\u0306',
      };
      final original = Map.of(input);
      expect(await engine.inflectRaw(GrammaticalCase.genitive, input), {
        'givenName': 'override',
        'custom': 'last',
      });
      expect(input, original);
      expect(events, ['start', 'end', 'second']);
    },
  );
  test(
    'duplicate registrations execute; instances stay isolated; missing hook allowed',
    () async {
      final engine = Shevchenko.core();
      var calls = 0;
      ShevchenkoExtension factory(ExtensionContext _) => ShevchenkoExtension(
        fieldNames: ['custom'],
        afterInflect: (_, _) {
          calls++;
          return null;
        },
      );
      engine.registerExtension(factory);
      engine.registerExtension(factory);
      engine.registerExtension((_) => ShevchenkoExtension(fieldNames: []));
      expect(
        await engine.inflectRaw(GrammaticalCase.genitive, {
          'gender': 'masculine',
          'custom': '',
        }),
        {},
      );
      expect(calls, 2);
      await expectLater(
        Shevchenko.core().inflectRaw(GrammaticalCase.genitive, {
          'gender': 'masculine',
          'custom': '',
        }),
        throwsA(isA<InputValidationException>()),
      );
      await expectLater(
        engine.inflectRaw(GrammaticalCase.genitive, {'gender': 'masculine'}),
        throwsA(
          isA<InputValidationException>().having(
            (e) => e.message,
            'duplicates',
            contains('"custom", "custom"'),
          ),
        ),
      );
    },
  );
  test(
    'failed hook prevents later execution; typed output rejects invalid standard values',
    () async {
      final engine = Shevchenko.core();
      var reached = false;
      engine.registerExtension(
        (_) => ShevchenkoExtension(
          fieldNames: [],
          afterInflect: (_, _) => throw StateError('hook'),
        ),
      );
      engine.registerExtension(
        (_) => ShevchenkoExtension(
          fieldNames: [],
          afterInflect: (_, _) {
            reached = true;
            return null;
          },
        ),
      );
      await expectLater(
        engine.inGenitive(
          const DeclensionInput(
            gender: GrammaticalGender.masculine,
            givenName: 'Тарас',
          ),
        ),
        throwsStateError,
      );
      expect(reached, false);
      final bad = Shevchenko.core()
        ..registerExtension(
          (_) => ShevchenkoExtension(
            fieldNames: [],
            afterInflect: (_, _) => {'givenName': 1},
          ),
        );
      expect(
        await bad.inflectRaw(GrammaticalCase.genitive, {
          'gender': 'masculine',
          'givenName': '',
        }),
        {'givenName': 1},
      );
      await expectLater(
        bad.inGenitive(
          const DeclensionInput(
            gender: GrammaticalGender.masculine,
            givenName: '',
          ),
        ),
        throwsStateError,
      );
    },
  );
  test(
    'typed absence, explicit null, empty, undefined and unknown-field behavior',
    () async {
      expect(
        const DeclensionInput(
          gender: GrammaticalGender.masculine,
          givenName: '',
        ).toJson(),
        {'gender': 'masculine', 'givenName': ''},
      );
      expect(
        () => DeclensionInput.fromJson({
          'gender': 'masculine',
          'givenName': null,
        }),
        throwsA(isA<InputValidationException>()),
      );
      expect(
        await compat.inGenitive({
          'gender': 'masculine',
          'givenName': '',
          'familyName': compat.Undefined.value,
          'unknown': 5,
        }),
        {'givenName': ''},
      );
      await expectLater(
        compat.inGenitive({
          'gender': 'masculine',
          'givenName': compat.Undefined.value,
        }),
        throwsA(isA<InputValidationException>()),
      );
      final fields = <String, Object?>{'x': 'one'};
      final input = DeclensionInput.withCustomFields(
        gender: GrammaticalGender.masculine,
        customFields: fields,
      );
      fields['x'] = 'two';
      expect(input.customFields['x'], 'one');
      expect(
        () => DeclensionInput.withCustomFields(
          gender: GrammaticalGender.masculine,
          customFields: {'gender': 'feminine'},
        ),
        throwsArgumentError,
      );
    },
  );
  test(
    'core-only factory can opt into military and concurrent calls are independent',
    () async {
      final core = Shevchenko.core();
      const extensionInput = DeclensionInput(
        gender: GrammaticalGender.feminine,
        familyName: 'Зелена',
        militaryRank: 'солдат',
      );
      expect((await core.inGenitive(extensionInput)).toJson(), {
        'familyName': 'Зеленої',
      });
      core.registerExtension(militaryExtension);
      const inputs = [
        DeclensionInput(
          gender: GrammaticalGender.feminine,
          familyName: 'Зелена',
          militaryRank: 'солдат',
        ),
        DeclensionInput(
          gender: GrammaticalGender.masculine,
          givenName: 'Тарас',
          militaryAppointment: 'помічник гранатометника',
        ),
        DeclensionInput(
          gender: GrammaticalGender.feminine,
          givenName: 'Оксана',
          familyName: 'Шевченко',
        ),
      ];
      const expected = [
        {'familyName': 'Зеленої', 'militaryRank': 'солдата'},
        {
          'givenName': 'Тараса',
          'militaryAppointment': 'помічника гранатометника',
        },
        {'givenName': 'Оксани', 'familyName': 'Шевченко'},
      ];
      final results = await Future.wait(
        List.generate(60, (index) => core.inGenitive(inputs[index % 3])),
      );
      for (var index = 0; index < results.length; index++) {
        expect(results[index].toJson(), expected[index % 3]);
      }
    },
  );
  test('inflection diagnostics explain core and extension results', () async {
    final result = await inflectWithDiagnostics(
      GrammaticalCase.genitive,
      const DeclensionInput(
        gender: GrammaticalGender.masculine,
        givenName: 'Тарас',
        patronymicName: 'невідоме',
        militaryRank: 'солдат',
      ),
    );
    expect(result.output.toJson(), {
      'givenName': 'Тараса',
      'patronymicName': 'невідоме',
      'militaryRank': 'солдата',
    });
    final given = result.diagnostics['givenName']!;
    expect(given.source, InflectionFieldSource.coreRules);
    expect(given.changed, true);
    expect(given.words.single.status, WordInflectionStatus.changed);
    expect(given.words.single.ruleDescription, isNotEmpty);
    expect(given.words.single.alternativeCount, greaterThanOrEqualTo(1));
    expect(
      result.diagnostics['patronymicName']!.words.single.status,
      WordInflectionStatus.noMatchingRule,
    );
    final rank = result.diagnostics['militaryRank']!;
    expect(rank.source, InflectionFieldSource.extension);
    expect(rank.words, isEmpty);
    expect(rank.changed, true);
    expect(() => result.diagnostics['other'] = given, throwsUnsupportedError);
    expect(() => given.words.add(given.words.single), throwsUnsupportedError);
  });
  test('later non-string extension output removes stale diagnostics', () async {
    final engine = Shevchenko.core()
      ..registerExtension(
        (_) => ShevchenkoExtension(
          fieldNames: ['custom'],
          afterInflect: (_, input) => {'custom': input['custom']},
        ),
      )
      ..registerExtension(
        (_) => ShevchenkoExtension(
          fieldNames: ['custom'],
          afterInflect: (_, _) => {'custom': 1},
        ),
      );
    final result = await engine.inflectWithDiagnostics(
      GrammaticalCase.genitive,
      DeclensionInput.withCustomFields(
        gender: GrammaticalGender.masculine,
        customFields: {'custom': 'value'},
      ),
    );
    expect(result.output.customFields, {'custom': 1});
    expect(result.diagnostics, isEmpty);
  });
  test(
    'gender diagnostics retain compatibility precedence and evidence',
    () async {
      final result = await detectGenderWithDiagnostics(
        const GenderDetectionInput(
          givenName: 'Оксана',
          patronymicName: 'Григорович',
        ),
      );
      expect(result.gender, GrammaticalGender.masculine);
      expect(result.source, GenderDetectionSource.patronymicName);
      expect(result.masculineMatchLength, greaterThan(0));
      expect(result.isAmbiguous, false);

      final empty = await Shevchenko().detectGenderWithDiagnostics(
        const GenderDetectionInput(familyName: 'Шевченко'),
      );
      expect(empty.gender, isNull);
      expect(empty.source, GenderDetectionSource.none);
      expect(empty.masculineMatchLength, 0);
      expect(empty.feminineMatchLength, 0);
    },
  );
}
