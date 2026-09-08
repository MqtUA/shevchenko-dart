import 'package:shevchenko/shevchenko.dart';
import 'package:shevchenko/shevchenko_compat.dart' show Undefined;
import 'package:test/test.dart';

void main() {
  test(
    'custom-only DTO round trip defers registered-field checks to the engine',
    () async {
      final original = DeclensionInput.withCustomFields(
        gender: GrammaticalGender.masculine,
        customFields: {'customName': 'И\u0306осип'},
      );
      final restored = DeclensionInput.fromJson(original.toJson());
      expect(restored, original);
      final engine = Shevchenko.core()
        ..registerExtension(
          (_) => ShevchenkoExtension(
            fieldNames: ['customName'],
            afterInflect: (_, input) => {'customName': input['customName']},
          ),
        );
      expect((await engine.inGenitive(restored)).customFields, {
        'customName': 'Йосип',
      });
      await expectLater(
        Shevchenko.core().inGenitive(restored),
        throwsA(isA<InputValidationException>()),
      );
    },
  );

  test(
    'DTO parsing preserves spelling until API normalization and handles undefined',
    () async {
      const original = DeclensionInput(
        gender: GrammaticalGender.masculine,
        givenName: 'И\u0306осип',
      );
      expect(DeclensionInput.fromJson(original.toJson()), original);
      expect(
        GenderDetectionInput.fromJson({'givenName': 'И\u0306осип'}),
        const GenderDetectionInput(givenName: 'И\u0306осип'),
      );
      expect(
        DeclensionInput.fromJson({
          'gender': 'masculine',
          'givenName': '',
          'familyName': Undefined.value,
        }).toJson(),
        {'gender': 'masculine', 'givenName': ''},
      );
      expect(
        () => DeclensionInput.fromJson({
          'gender': 'masculine',
          'givenName': null,
        }),
        throwsA(isA<InputValidationException>()),
      );
    },
  );

  test(
    'raw hook input is snapshotted before yielding and retains JSON map typing',
    () async {
      final nested = <String, Object?>{'value': 'before'};
      final engine = Shevchenko.core()
        ..registerExtension(
          (_) => ShevchenkoExtension(
            fieldNames: [],
            afterInflect: (_, input) {
              final metadata = input['metadata'] as Map<String, Object?>;
              expect(metadata['value'], 'before');
              expect(() => metadata['value'] = 'hook', throwsUnsupportedError);
              return {'seen': metadata['value']};
            },
          ),
        );
      final result = engine.inflectRaw(GrammaticalCase.genitive, {
        'gender': 'masculine',
        'givenName': 'Тарас',
        'metadata': nested,
      });
      nested['value'] = 'after';
      expect(await result, {'givenName': 'Тараса', 'seen': 'before'});
      expect(nested['value'], 'after');
    },
  );

  test(
    'in-flight registry snapshot is independent of later registration',
    () async {
      final engine = Shevchenko.core();
      final input = {'gender': 'masculine', 'givenName': 'Тарас'};
      final first = engine.inflectRaw(GrammaticalCase.genitive, input);
      engine.registerExtension(
        (_) => ShevchenkoExtension(
          fieldNames: [],
          afterInflect: (_, _) => {'extra': true},
        ),
      );
      expect(await first, {'givenName': 'Тараса'});
      expect(await engine.inflectRaw(GrammaticalCase.genitive, input), {
        'givenName': 'Тараса',
        'extra': true,
      });
    },
  );
}
