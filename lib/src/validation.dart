import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// Explicit undefined for the compatibility adapter. JSON omission is preferred.
enum Undefined { value }

/// Validation failure retaining the upstream message and a stable Dart code.
final class InputValidationException implements Exception {
  const InputValidationException(this.message, this.code);
  final String message;
  final String code;
  @override
  String toString() => 'InputValidationException: $message';
}

const nameFields = ['givenName', 'patronymicName', 'familyName'];
const standardFields = [...nameFields, 'militaryRank', 'militaryAppointment'];

Map<String, Object?> validateInput(
  Object? input, {
  bool genderRequired = true,
  List<String> extraFields = const [],
  bool requireFields = true,
  bool normalize = true,
}) {
  // JS arrays pass the object check, then fail missing gender/fields.
  if (input is! Map && input is! List) {
    throw const InputValidationException(
      'The input type must be an object.',
      'invalidInput',
    );
  }
  if (input is Map && input.keys.any((key) => key is! String)) {
    throw const InputValidationException(
      'The input type must be an object with string keys.',
      'invalidInput',
    );
  }
  final map = input is Map
      ? input.cast<String, Object?>()
      : <String, Object?>{};
  if (genderRequired && !['masculine', 'feminine'].contains(map['gender'])) {
    throw const InputValidationException(
      'The "gender" parameter must be one of the following: "masculine", "feminine".',
      'invalidGender',
    );
  }
  final fields = [...nameFields, if (genderRequired) ...extraFields];
  if (requireFields &&
      !fields.any(
        (key) => map.containsKey(key) && map[key] != Undefined.value,
      )) {
    throw InputValidationException(
      'At least one of the following parameters must present: "${fields.join('", "')}".',
      'missingFields',
    );
  }
  for (final field in fields) {
    if (map.containsKey(field) &&
        map[field] != Undefined.value &&
        map[field] is! String) {
      throw InputValidationException(
        'The "$field" parameter must be a string.',
        'invalidField',
      );
    }
  }
  final output = Map<String, Object?>.of(map);
  for (final field in fields) {
    final value = output[field];
    if (normalize && value is String) output[field] = unorm.nfc(value);
  }
  return output;
}
