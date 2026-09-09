# shevchenko-dart

**English** | [Українська](https://github.com/MqtUA/shevchenko-dart/blob/main/README.uk.md)

Pure Dart declension of Ukrainian given names, patronymics, family names,
military ranks, and military appointments. The package supports all seven
Ukrainian grammatical cases, gender detection, typed and Map-based APIs,
Flutter, native Dart, JavaScript, and WebAssembly.

The implementation is based on
[shevchenko.js](https://github.com/tooleks/shevchenko-js) and
[shevchenko-ext-military](https://github.com/tooleks/shevchenko-ext-military).
Rules, Unicode normalization, and the family-name classifier run locally.

## Installation

The package requires Dart 3.11 or later within the Dart 3 release line.

```sh
dart pub add shevchenko
```

For Flutter projects, use `flutter pub add shevchenko`.

## Quick start

```dart
import 'package:shevchenko/shevchenko.dart' as s;

Future<void> main() async {
  final result = await s.inGenitive(const s.DeclensionInput(
    gender: s.GrammaticalGender.masculine,
    givenName: 'Тарас',
    patronymicName: 'Григорович',
    familyName: 'Шевченко',
    militaryRank: 'солдат',
    militaryAppointment: 'помічник гранатометника',
  ));

  print(result.givenName); // Тараса
  print(result.patronymicName); // Григоровича
  print(result.familyName); // Шевченка
  print(result.militaryRank); // солдата
  print(result.militaryAppointment); // помічника гранатометника
}
```

All operations return `Future` values. No model initialization or network
connection is required.

## Cases

| Ukrainian case | Convenience method | `GrammaticalCase` |
| --- | --- | --- |
| Nominative | `inNominative` | `nominative` |
| Genitive | `inGenitive` | `genitive` |
| Dative | `inDative` | `dative` |
| Accusative | `inAccusative` | `accusative` |
| Instrumental | `inAblative` | `ablative` |
| Locative | `inLocative` | `locative` |
| Vocative | `inVocative` | `vocative` |

The `ablative` name is retained for compatibility with the original API.
For a case selected at runtime, use `Shevchenko().inflect(caseValue, input)`.

## Full names

`FullNameInput` requires an explicit component layout because two-component
values cannot reliably distinguish a family name from a patronymic.

```dart
final declined = await s.inflectFullName(
  s.GrammaticalCase.genitive,
  s.FullNameInput(
    fullName: 'Шевченко Тарас Григорович',
    gender: s.GrammaticalGender.masculine,
    format: s.FullNameFormat.familyGivenPatronymic,
  ),
); // Шевченка Тараса Григоровича
```

Supported layouts are `givenPatronymicFamily`, `familyGivenPatronymic`,
`givenFamily`, `familyGiven`, and `givenPatronymic`. Use `inflectFullNames()`
for an ordered list of names.

## Gender detection

```dart
final gender = await s.detectGender(
  const s.GenderDetectionInput(givenName: 'Оксана'),
); // GrammaticalGender.feminine
```

A non-empty patronymic takes precedence over a given name. Detection returns
`null` when no pattern matches; a family name alone does not determine gender.

## Diagnostics

Use diagnostics when an application needs to explain an unchanged word or
inspect the selected rule.

```dart
final result = await s.inflectWithDiagnostics(
  s.GrammaticalCase.genitive,
  const s.DeclensionInput(
    gender: s.GrammaticalGender.masculine,
    givenName: 'Тарас',
  ),
);

print(result.output.givenName); // Тараса
final word = result.diagnostics['givenName']!.words.single;
print(word.status); // WordInflectionStatus.changed
print(word.ruleDescription);
```

`detectGenderWithDiagnostics()` additionally reports whether the given name or
patronymic was used and the masculine and feminine pattern-match lengths.

## Extensions

Extensions belong to a `Shevchenko` instance, which keeps configuration local
and prevents one part of an application from changing another part's engine.
Military support is enabled by default. Use `Shevchenko.core()` for a core-only
engine.

```dart
final engine = s.Shevchenko.core();
engine.registerExtension(s.militaryExtension);
```

An extension can register custom fields and use the same `WordInflector` as the
core engine:

```dart
final engine = s.Shevchenko.core()
  ..registerExtension((context) => s.ShevchenkoExtension(
    fieldNames: ['customName'],
    afterInflect: (grammaticalCase, input) async {
      final value = input['customName'];
      if (value is! String) return null;
      return {
        'customName': await context.wordInflector.inflect(
          value,
          s.DeclensionParams(
            grammaticalCase: grammaticalCase,
            gender: s.GrammaticalGender.values.byName(
              input['gender']! as String,
            ),
          ),
        ),
      };
    },
  ));
```

Extensions run sequentially. Later extension results may replace earlier
fields. Input maps passed to hooks are normalized and read-only.

## Map and JSON adapter

Existing Map-based integrations can use the separate compatibility entrypoint:

```dart
import 'package:shevchenko/shevchenko_compat.dart' as compat;

final result = await compat.inGenitive({
  'gender': 'masculine',
  'givenName': 'Тарас',
});
```

The typed API rejects invalid values earlier and is recommended for new code.
`null` means an absent typed field; omit absent keys in JSON. Input strings are
normalized to NFC but are not trimmed or space-collapsed.

## Compatibility and development

The behavioral compatibility target is shevchenko.js 3.2.2 with
shevchenko-ext-military beta.3. See
[Compatibility contract](doc/COMPATIBILITY.md) for preserved edge cases and
known differences, and [Development](doc/DEVELOPMENT.md) for fixture generation,
browser checks, benchmarks, and release validation.

The repository includes CLI, Dart Web, and Flutter examples under `example/`.

## License

MIT. See [LICENSE](LICENSE) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
