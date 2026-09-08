import 'package:shevchenko/shevchenko.dart';
import 'package:shevchenko/shevchenko_compat.dart' as compat;
import 'package:test/test.dart';

void main() {
  group('common Ukrainian name combinations', () {
    test('Тарас Григорович Шевченко', () async {
      final result = await inGenitive(
        const DeclensionInput(
          gender: GrammaticalGender.masculine,
          givenName: 'Тарас',
          patronymicName: 'Григорович',
          familyName: 'Шевченко',
        ),
      );
      expect(result.toJson(), {
        'givenName': 'Тараса',
        'patronymicName': 'Григоровича',
        'familyName': 'Шевченка',
      });
    });

    test('Шевченко Тарас Григорович: input key order is irrelevant', () async {
      final result = await compat.inGenitive({
        'familyName': 'Шевченко',
        'givenName': 'Тарас',
        'patronymicName': 'Григорович',
        'gender': 'masculine',
      });
      expect(result, {
        'givenName': 'Тараса',
        'patronymicName': 'Григоровича',
        'familyName': 'Шевченка',
      });
    });

    test('Тарас Шевченко', () async {
      final result = await inGenitive(
        const DeclensionInput(
          gender: GrammaticalGender.masculine,
          givenName: 'Тарас',
          familyName: 'Шевченко',
        ),
      );
      expect(result.toJson(), {
        'givenName': 'Тараса',
        'familyName': 'Шевченка',
      });
    });

    test('Тарас Григорович', () async {
      final result = await inGenitive(
        const DeclensionInput(
          gender: GrammaticalGender.masculine,
          givenName: 'Тарас',
          patronymicName: 'Григорович',
        ),
      );
      expect(result.toJson(), {
        'givenName': 'Тараса',
        'patronymicName': 'Григоровича',
      });
    });

    test('full-name strings use explicit formats', () async {
      final cases = <FullNameInput>[
        FullNameInput(
          fullName: 'Тарас Григорович Шевченко',
          gender: GrammaticalGender.masculine,
          format: FullNameFormat.givenPatronymicFamily,
        ),
        FullNameInput(
          fullName: 'Шевченко Тарас Григорович',
          gender: GrammaticalGender.masculine,
          format: FullNameFormat.familyGivenPatronymic,
        ),
        FullNameInput(
          fullName: 'Тарас Шевченко',
          gender: GrammaticalGender.masculine,
          format: FullNameFormat.givenFamily,
        ),
        FullNameInput(
          fullName: 'Шевченко Тарас',
          gender: GrammaticalGender.masculine,
          format: FullNameFormat.familyGiven,
        ),
        FullNameInput(
          fullName: 'Тарас Григорович',
          gender: GrammaticalGender.masculine,
          format: FullNameFormat.givenPatronymic,
        ),
      ];

      expect(await inflectFullNames(GrammaticalCase.genitive, cases), [
        'Тараса Григоровича Шевченка',
        'Шевченка Тараса Григоровича',
        'Тараса Шевченка',
        'Шевченка Тараса',
        'Тараса Григоровича',
      ]);
    });

    test('full-name output rejects a result with a required field missing', () {
      final input = FullNameInput(
        fullName: 'Шевченко Тарас',
        gender: GrammaticalGender.masculine,
        format: FullNameFormat.familyGiven,
      );
      expect(
        () => input.formatOutput(const DeclensionOutput(givenName: 'Тараса')),
        throwsStateError,
      );
    });

    test(
      'full-name parsing normalizes surrounding and repeated whitespace',
      () {
        final input = FullNameInput(
          fullName: '  Тарас\t Григорович  Шевченко ',
          gender: GrammaticalGender.masculine,
          format: FullNameFormat.givenPatronymicFamily,
        );
        expect(input.fullName, 'Тарас\t Григорович  Шевченко');
        expect(input.toDeclensionInput().toJson(), {
          'gender': 'masculine',
          'givenName': 'Тарас',
          'patronymicName': 'Григорович',
          'familyName': 'Шевченко',
        });
      },
    );

    test('ambiguous or mismatched full-name layouts are rejected', () {
      expect(
        () => FullNameInput(
          fullName: 'Тарас Шевченко',
          gender: GrammaticalGender.masculine,
          format: FullNameFormat.givenPatronymicFamily,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
