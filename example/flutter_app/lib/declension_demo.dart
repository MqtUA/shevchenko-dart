import 'package:shevchenko/shevchenko.dart' as s;

const _caseLabels = <s.GrammaticalCase, String>{
  s.GrammaticalCase.nominative: 'Називний',
  s.GrammaticalCase.genitive: 'Родовий',
  s.GrammaticalCase.dative: 'Давальний',
  s.GrammaticalCase.accusative: 'Знахідний',
  s.GrammaticalCase.ablative: 'Орудний',
  s.GrammaticalCase.locative: 'Місцевий',
  s.GrammaticalCase.vocative: 'Кличний',
};

Future<Map<String, String>> declineAllCases({
  required String rank,
  required String fullName,
  required String appointment,
  required s.GrammaticalGender gender,
}) async {
  final normalizedRank = rank.trim();
  final normalizedFullName = fullName.trim();
  final normalizedAppointment = appointment.trim();
  if (normalizedRank.isEmpty &&
      normalizedFullName.isEmpty &&
      normalizedAppointment.isEmpty) {
    throw const FormatException('Заповніть хоча б одне поле.');
  }

  final engine = s.Shevchenko();
  final parsedName = normalizedFullName.isEmpty
      ? null
      : await _parseFullName(engine, normalizedFullName, gender);
  final input = s.DeclensionInput(
    gender: gender,
    givenName: parsedName?.givenName,
    patronymicName: parsedName?.patronymicName,
    familyName: parsedName?.familyName,
    militaryRank: normalizedRank.isEmpty ? null : normalizedRank,
    militaryAppointment: normalizedAppointment.isEmpty
        ? null
        : normalizedAppointment,
  );

  final output = <String, String>{};
  for (final grammaticalCase in s.GrammaticalCase.values) {
    final result = await engine.inflect(grammaticalCase, input);
    output[_caseLabels[grammaticalCase]!] = [
      result.militaryRank,
      if (parsedName != null) parsedName.formatOutput(result),
      result.militaryAppointment,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' ');
  }
  return output;
}

Future<s.FullNameInput> _parseFullName(
  s.Shevchenko engine,
  String text,
  s.GrammaticalGender gender,
) async {
  final parts = text.split(RegExp(r'\s+'));
  if (parts.length < 2 || parts.length > 3) {
    throw const FormatException(
      'Введіть ім’я з прізвищем, ім’я з по батькові або повне ПІБ.',
    );
  }

  final s.FullNameFormat format;
  if (parts.length == 2) {
    if (_looksLikePatronymic(parts[1])) {
      format = s.FullNameFormat.givenPatronymic;
    } else {
      final firstGender = await engine.detectGender(
        s.GenderDetectionInput(givenName: parts[0]),
      );
      final secondGender = await engine.detectGender(
        s.GenderDetectionInput(givenName: parts[1]),
      );
      final surnameFirst =
          secondGender != null &&
          (firstGender == null ||
              (_looksLikeFamilyName(parts[0]) &&
                  !_looksLikeFamilyName(parts[1])));
      if (surnameFirst) {
        format = s.FullNameFormat.familyGiven;
      } else if (firstGender != null) {
        format = s.FullNameFormat.givenFamily;
      } else {
        throw const FormatException(
          'Не вдалося визначити порядок імені та прізвища. Додайте по батькові.',
        );
      }
    }
  } else if (_looksLikePatronymic(parts[1])) {
    format = s.FullNameFormat.givenPatronymicFamily;
  } else if (_looksLikePatronymic(parts[2])) {
    format = s.FullNameFormat.familyGivenPatronymic;
  } else {
    throw const FormatException(
      'Не вдалося визначити порядок повного ПІБ. Перевірте по батькові.',
    );
  }

  return s.FullNameInput(fullName: text, gender: gender, format: format);
}

bool _looksLikePatronymic(String value) => RegExp(
  r'(ович|евич|євич|йович|ич|івна|ївна|овна|евна|євна)$',
  caseSensitive: false,
).hasMatch(value);

bool _looksLikeFamilyName(String value) => RegExp(
  r'(енко|єнко|ко|ук|юк|чук|щук|чак|як|ський|цький|зький|ова|ева|єва|іна|їна)$',
  caseSensitive: false,
).hasMatch(value);
