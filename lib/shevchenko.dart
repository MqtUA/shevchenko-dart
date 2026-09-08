/// Pure Dart Ukrainian declension, including built-in military support.
library;

import 'src/api.dart';
import 'src/extensions.dart';
import 'src/language.dart';
export 'src/api.dart'
    show
        Shevchenko,
        DeclensionInput,
        DeclensionOutput,
        GenderDetectionInput,
        FullNameInput,
        FullNameFormat;
export 'src/declension.dart';
export 'src/extensions.dart';
export 'src/language.dart'
    show GrammaticalCase, GrammaticalGender, WordClass, ApplicationType;
export 'src/military.dart' show militaryExtension;
export 'src/validation.dart' show InputValidationException;

void registerExtension(ExtensionFactory factory) =>
    defaultShevchenko.registerExtension(factory);
Future<GrammaticalGender?> detectGender(GenderDetectionInput input) =>
    defaultShevchenko.detectGender(input);
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
