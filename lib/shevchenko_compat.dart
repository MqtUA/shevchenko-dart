/// Map/JSON adapter sharing the standard instance and engine with the typed API.
library;

import 'src/api.dart';
import 'src/language.dart';
export 'src/validation.dart' show Undefined, InputValidationException;

Future<String?> detectGender(Object? input) async =>
    (await defaultShevchenko.detectGenderRaw(input))?.name;
Future<Map<String, Object?>> inNominative(Object? input) =>
    defaultShevchenko.inflectRaw(GrammaticalCase.nominative, input);
Future<Map<String, Object?>> inGenitive(Object? input) =>
    defaultShevchenko.inflectRaw(GrammaticalCase.genitive, input);
Future<Map<String, Object?>> inDative(Object? input) =>
    defaultShevchenko.inflectRaw(GrammaticalCase.dative, input);
Future<Map<String, Object?>> inAccusative(Object? input) =>
    defaultShevchenko.inflectRaw(GrammaticalCase.accusative, input);
Future<Map<String, Object?>> inAblative(Object? input) =>
    defaultShevchenko.inflectRaw(GrammaticalCase.ablative, input);
Future<Map<String, Object?>> inLocative(Object? input) =>
    defaultShevchenko.inflectRaw(GrammaticalCase.locative, input);
Future<Map<String, Object?>> inVocative(Object? input) =>
    defaultShevchenko.inflectRaw(GrammaticalCase.vocative, input);
