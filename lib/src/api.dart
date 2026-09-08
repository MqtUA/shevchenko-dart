import 'classifier.dart';
import 'declension.dart';
import 'extensions.dart';
import 'generated/data.dart';
import 'language.dart';
import 'military.dart';
import 'validation.dart';
import 'values.dart';

String? _optionalString(Map<String, Object?> input, String key) =>
    input[key] == Undefined.value ? null : input[key] as String?;

Map<String, Object?> _customCopy(Map<String, Object?> fields) {
  if (fields.keys.any(
    (key) => standardFields.contains(key) || key == 'gender',
  )) {
    throw ArgumentError(
      'customFields must not contain standard fields or gender.',
    );
  }
  return freezeFields(fields);
}

/// The supported, unambiguous component layouts of a full-name string.
enum FullNameFormat {
  givenPatronymicFamily,
  familyGivenPatronymic,
  givenFamily,
  familyGiven,
  givenPatronymic,
}

/// A full-name string with an explicit layout.
///
/// The layout is required because two components such as `Тарас Шевченко` and
/// `Тарас Григорович` cannot be distinguished reliably by their text alone.
final class FullNameInput {
  factory FullNameInput({
    required String fullName,
    required GrammaticalGender gender,
    required FullNameFormat format,
  }) {
    final trimmed = fullName.trim();
    final parts = trimmed.isEmpty
        ? const <String>[]
        : trimmed.split(RegExp(r'\s+'));
    final expectedLength = switch (format) {
      FullNameFormat.givenPatronymicFamily ||
      FullNameFormat.familyGivenPatronymic => 3,
      FullNameFormat.givenFamily ||
      FullNameFormat.familyGiven ||
      FullNameFormat.givenPatronymic => 2,
    };
    if (parts.length != expectedLength) {
      throw FormatException(
        'FullNameFormat.${format.name} requires exactly $expectedLength '
        'whitespace-separated components, but got ${parts.length}.',
        fullName,
      );
    }

    final (givenName, patronymicName, familyName) = switch (format) {
      FullNameFormat.givenPatronymicFamily => (parts[0], parts[1], parts[2]),
      FullNameFormat.familyGivenPatronymic => (parts[1], parts[2], parts[0]),
      FullNameFormat.givenFamily => (parts[0], null, parts[1]),
      FullNameFormat.familyGiven => (parts[1], null, parts[0]),
      FullNameFormat.givenPatronymic => (parts[0], parts[1], null),
    };
    return FullNameInput._(
      fullName: trimmed,
      gender: gender,
      format: format,
      givenName: givenName,
      patronymicName: patronymicName,
      familyName: familyName,
    );
  }

  const FullNameInput._({
    required this.fullName,
    required this.gender,
    required this.format,
    required this.givenName,
    required this.patronymicName,
    required this.familyName,
  });

  final String fullName;
  final GrammaticalGender gender;
  final FullNameFormat format;
  final String givenName;
  final String? patronymicName;
  final String? familyName;

  DeclensionInput toDeclensionInput() => DeclensionInput(
    gender: gender,
    givenName: givenName,
    patronymicName: patronymicName,
    familyName: familyName,
  );

  /// Reassembles a declined structured result in this input's layout.
  String formatOutput(DeclensionOutput output) => switch (format) {
    FullNameFormat.givenPatronymicFamily =>
      '${_require(output.givenName, 'givenName')} '
          '${_require(output.patronymicName, 'patronymicName')} '
          '${_require(output.familyName, 'familyName')}',
    FullNameFormat.familyGivenPatronymic =>
      '${_require(output.familyName, 'familyName')} '
          '${_require(output.givenName, 'givenName')} '
          '${_require(output.patronymicName, 'patronymicName')}',
    FullNameFormat.givenFamily =>
      '${_require(output.givenName, 'givenName')} '
          '${_require(output.familyName, 'familyName')}',
    FullNameFormat.familyGiven =>
      '${_require(output.familyName, 'familyName')} '
          '${_require(output.givenName, 'givenName')}',
    FullNameFormat.givenPatronymic =>
      '${_require(output.givenName, 'givenName')} '
          '${_require(output.patronymicName, 'patronymicName')}',
  };

  static String _require(String? value, String field) {
    if (value == null) {
      throw StateError('Declension output is missing required field "$field".');
    }
    return value;
  }
}

/// A typed request. Null means absent; an empty string is a supplied field.
final class DeclensionInput {
  @override
  bool operator ==(Object other) =>
      other is DeclensionInput && equalValues(toJson(), other.toJson());
  @override
  int get hashCode => hashValue(toJson());
  const DeclensionInput({
    required this.gender,
    this.givenName,
    this.patronymicName,
    this.familyName,
    this.militaryRank,
    this.militaryAppointment,
  }) : customFields = const {};
  DeclensionInput.withCustomFields({
    required this.gender,
    this.givenName,
    this.patronymicName,
    this.familyName,
    this.militaryRank,
    this.militaryAppointment,
    required Map<String, Object?> customFields,
  }) : customFields = _customCopy(customFields);
  factory DeclensionInput.fromJson(Map<String, Object?> json) {
    final valid = validateInput(
      json,
      extraFields: standardFields.skip(3).toList(),
      requireFields: false,
      normalize: false,
    );
    return DeclensionInput.withCustomFields(
      gender: GrammaticalGender.values.byName(valid['gender']! as String),
      givenName: _optionalString(valid, 'givenName'),
      patronymicName: _optionalString(valid, 'patronymicName'),
      familyName: _optionalString(valid, 'familyName'),
      militaryRank: _optionalString(valid, 'militaryRank'),
      militaryAppointment: _optionalString(valid, 'militaryAppointment'),
      customFields: {...valid}
        ..removeWhere(
          (key, _) => key == 'gender' || standardFields.contains(key),
        ),
    );
  }
  final GrammaticalGender gender;
  final String? givenName,
      patronymicName,
      familyName,
      militaryRank,
      militaryAppointment;
  final Map<String, Object?> customFields;
  Map<String, Object?> toJson() => {
    'gender': gender.name,
    if (givenName != null) 'givenName': givenName,
    if (patronymicName != null) 'patronymicName': patronymicName,
    if (familyName != null) 'familyName': familyName,
    if (militaryRank != null) 'militaryRank': militaryRank,
    if (militaryAppointment != null) 'militaryAppointment': militaryAppointment,
    ...customFields,
  };
}

final class GenderDetectionInput {
  @override
  bool operator ==(Object other) =>
      other is GenderDetectionInput && equalValues(toJson(), other.toJson());
  @override
  int get hashCode => hashValue(toJson());
  const GenderDetectionInput({
    this.givenName,
    this.patronymicName,
    this.familyName,
  });
  factory GenderDetectionInput.fromJson(Map<String, Object?> json) {
    final valid = validateInput(
      json,
      genderRequired: false,
      requireFields: false,
      normalize: false,
    );
    return GenderDetectionInput(
      givenName: _optionalString(valid, 'givenName'),
      patronymicName: _optionalString(valid, 'patronymicName'),
      familyName: _optionalString(valid, 'familyName'),
    );
  }
  final String? givenName, patronymicName, familyName;
  Map<String, Object?> toJson() => {
    if (givenName != null) 'givenName': givenName,
    if (patronymicName != null) 'patronymicName': patronymicName,
    if (familyName != null) 'familyName': familyName,
  };
}

/// Declined fields, omitting absent fields and gender.
final class DeclensionOutput {
  const DeclensionOutput({
    this.givenName,
    this.patronymicName,
    this.familyName,
    this.militaryRank,
    this.militaryAppointment,
  }) : customFields = const {};
  DeclensionOutput.withCustomFields({
    this.givenName,
    this.patronymicName,
    this.familyName,
    this.militaryRank,
    this.militaryAppointment,
    required Map<String, Object?> customFields,
  }) : customFields = _customCopy(customFields);
  @override
  bool operator ==(Object other) =>
      other is DeclensionOutput && equalValues(toJson(), other.toJson());
  @override
  int get hashCode => hashValue(toJson());
  factory DeclensionOutput.fromJson(Map<String, Object?> json) {
    for (final field in standardFields) {
      if (json.containsKey(field) && json[field] is! String) {
        throw StateError('Extension output "$field" must be a string.');
      }
    }
    if (json.containsKey('gender')) {
      throw StateError('Typed output cannot contain gender.');
    }
    return DeclensionOutput.withCustomFields(
      givenName: json['givenName'] as String?,
      patronymicName: json['patronymicName'] as String?,
      familyName: json['familyName'] as String?,
      militaryRank: json['militaryRank'] as String?,
      militaryAppointment: json['militaryAppointment'] as String?,
      customFields: {...json}
        ..removeWhere((key, _) => standardFields.contains(key)),
    );
  }
  final String? givenName,
      patronymicName,
      familyName,
      militaryRank,
      militaryAppointment;
  final Map<String, Object?> customFields;
  Map<String, Object?> toJson() => {
    if (givenName != null) 'givenName': givenName,
    if (patronymicName != null) 'patronymicName': patronymicName,
    if (familyName != null) 'familyName': familyName,
    if (militaryRank != null) 'militaryRank': militaryRank,
    if (militaryAppointment != null) 'militaryAppointment': militaryAppointment,
    ...customFields,
  };
}

/// Instance-local extension registry. Military is enabled by default.
final class Shevchenko {
  Shevchenko() : this._(true);
  Shevchenko.core() : this._(false);
  Shevchenko._(bool military) {
    if (military) registerExtension(militaryExtension);
  }
  final WordInflector _words = WordInflector(defaultRules);
  final FamilyNameClassifier _classifier = FamilyNameClassifier();
  final List<ShevchenkoExtension> _extensions = [];

  void registerExtension(ExtensionFactory factory) {
    _extensions.add(factory(ExtensionContext(wordInflector: _words)));
  }

  Future<DeclensionOutput> inflect(
    GrammaticalCase grammaticalCase,
    DeclensionInput input,
  ) async => DeclensionOutput.fromJson(
    await inflectRaw(grammaticalCase, input.toJson()),
  );

  /// Inflects a full-name string and returns it in its original layout.
  Future<String> inflectFullName(
    GrammaticalCase grammaticalCase,
    FullNameInput input,
  ) async => input.formatOutput(
    await inflect(grammaticalCase, input.toDeclensionInput()),
  );

  /// Inflects full names sequentially and preserves their input order.
  Future<List<String>> inflectFullNames(
    GrammaticalCase grammaticalCase,
    Iterable<FullNameInput> inputs,
  ) async {
    final snapshot = List<FullNameInput>.of(inputs);
    final results = <String>[];
    for (final input in snapshot) {
      results.add(await inflectFullName(grammaticalCase, input));
    }
    return results;
  }

  /// Shared engine for the map adapter. Unknown input keys reach hooks only.
  Future<Map<String, Object?>> inflectRaw(
    GrammaticalCase grammaticalCase,
    Object? input,
  ) async {
    final extensions = List<ShevchenkoExtension>.of(_extensions);
    // Snapshot nested JSON data before any await permits caller mutation.
    final valid = freezeFields(
      validateInput(
        input,
        extraFields: extensions
            .expand((extension) => extension.fieldNames)
            .toList(),
      ),
    );
    final gender = GrammaticalGender.values.byName(valid['gender']! as String);
    final result = <String, Object?>{};
    for (final field in ApplicationType.values) {
      final value = valid[field.name];
      if (value is! String) continue;
      final parts = value.split('-');
      final output = <String>[];
      for (var i = 0; i < parts.length; i++) {
        final word = parts[i];
        WordClass? wordClass;
        if (field == ApplicationType.familyName) {
          if (i != parts.length - 1 &&
              RegExp(
                    '[аоуеиіяюєї]',
                    caseSensitive: false,
                  ).allMatches(word).length ==
                  1) {
            output.add(word);
            continue;
          }
          if (RegExp(
            gender == GrammaticalGender.feminine ? r'[ая]$' : r'(ой|ий|ій|их)$',
            caseSensitive: false,
          ).hasMatch(word)) {
            wordClass = _classifier.classify(word);
          }
        }
        output.add(
          await _words.inflect(
            word,
            DeclensionParams(
              grammaticalCase: grammaticalCase,
              gender: gender,
              wordClass: wordClass,
              applicationType: field,
              customRuleFilter: field == ApplicationType.patronymicName
                  ? (rule, _, _) => rule.applicationType.contains(
                      ApplicationType.patronymicName,
                    )
                  : null,
            ),
          ),
        );
      }
      result[field.name] = output.join('-');
    }
    for (final extension in extensions) {
      final extra = await extension.afterInflect?.call(grammaticalCase, valid);
      if (extra != null) result.addAll(extra);
    }
    return result;
  }

  Future<GrammaticalGender?> detectGender(GenderDetectionInput input) =>
      detectGenderRaw(input.toJson());
  Future<GrammaticalGender?> detectGenderRaw(Object? input) async {
    final valid = validateInput(input, genderRequired: false);
    final patronymic = valid['patronymicName'];
    final given = valid['givenName'];
    final String word;
    final Map<String, String> patterns;
    if (patronymic is String && patronymic.isNotEmpty) {
      word = patronymic.toLowerCase();
      patterns = patronymicGenderPatterns;
    } else if (given is String && given.isNotEmpty) {
      word = given.toLowerCase();
      patterns = givenGenderPatterns;
    } else {
      return null;
    }
    final masculine = RegExp(
      patterns['masculine']!,
      caseSensitive: false,
    ).firstMatch(word);
    final feminine = RegExp(
      patterns['feminine']!,
      caseSensitive: false,
    ).firstMatch(word);
    if (masculine == null) {
      return feminine == null ? null : GrammaticalGender.feminine;
    }
    if (feminine == null) return GrammaticalGender.masculine;
    return masculine[0]!.length > feminine[0]!.length
        ? GrammaticalGender.masculine
        : GrammaticalGender.feminine;
  }

  Future<DeclensionOutput> inNominative(DeclensionInput input) =>
      inflect(GrammaticalCase.nominative, input);
  Future<DeclensionOutput> inGenitive(DeclensionInput input) =>
      inflect(GrammaticalCase.genitive, input);
  Future<DeclensionOutput> inDative(DeclensionInput input) =>
      inflect(GrammaticalCase.dative, input);
  Future<DeclensionOutput> inAccusative(DeclensionInput input) =>
      inflect(GrammaticalCase.accusative, input);
  Future<DeclensionOutput> inAblative(DeclensionInput input) =>
      inflect(GrammaticalCase.ablative, input);
  Future<DeclensionOutput> inLocative(DeclensionInput input) =>
      inflect(GrammaticalCase.locative, input);
  Future<DeclensionOutput> inVocative(DeclensionInput input) =>
      inflect(GrammaticalCase.vocative, input);
}

final defaultShevchenko = Shevchenko();
