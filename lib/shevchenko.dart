/// Pure Dart Ukrainian declension, including built-in military support.
library;

import 'src/api.dart';
import 'src/language.dart';
export 'src/api.dart'
    show
        Shevchenko,
        DeclensionInput,
        DeclensionOutput,
        InflectionResult,
        InflectionFieldDiagnostic,
        InflectionFieldSource,
        GenderDetectionInput,
        GenderDetectionResult,
        GenderDetectionSource,
        FullNameInput,
        FullNameFormat;
export 'src/declension.dart';
export 'src/extensions.dart';
export 'src/language.dart'
    show GrammaticalCase, GrammaticalGender, WordClass, ApplicationType;
export 'src/military.dart' show militaryExtension;
export 'src/validation.dart' show InputValidationException;

Future<GrammaticalGender?> detectGender(GenderDetectionInput input) =>
    defaultShevchenko.detectGender(input);
Future<GenderDetectionResult> detectGenderWithDiagnostics(
  GenderDetectionInput input,
) => defaultShevchenko.detectGenderWithDiagnostics(input);
Future<InflectionResult> inflectWithDiagnostics(
  GrammaticalCase grammaticalCase,
  DeclensionInput input,
) => defaultShevchenko.inflectWithDiagnostics(grammaticalCase, input);
Future<String> inflectFullName(
  GrammaticalCase grammaticalCase,
  FullNameInput input,
) => defaultShevchenko.inflectFullName(grammaticalCase, input);
Future<List<String>> inflectFullNames(
  GrammaticalCase grammaticalCase,
  Iterable<FullNameInput> inputs,
) => defaultShevchenko.inflectFullNames(grammaticalCase, inputs);
Future<DeclensionOutput> inNominative(DeclensionInput input) =>
    defaultShevchenko.inNominative(input);
Future<DeclensionOutput> inGenitive(DeclensionInput input) =>
    defaultShevchenko.inGenitive(input);
Future<DeclensionOutput> inDative(DeclensionInput input) =>
    defaultShevchenko.inDative(input);
Future<DeclensionOutput> inAccusative(DeclensionInput input) =>
    defaultShevchenko.inAccusative(input);
Future<DeclensionOutput> inAblative(DeclensionInput input) =>
    defaultShevchenko.inAblative(input);
Future<DeclensionOutput> inLocative(DeclensionInput input) =>
    defaultShevchenko.inLocative(input);
Future<DeclensionOutput> inVocative(DeclensionInput input) =>
    defaultShevchenko.inVocative(input);
