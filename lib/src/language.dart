/// The seven upstream grammatical cases. Ablative is the Ukrainian instrumental.
enum GrammaticalCase {
  nominative,
  genitive,
  dative,
  accusative,
  ablative,
  locative,
  vocative,
}

/// Grammatical gender used for declension.
enum GrammaticalGender { masculine, feminine }

/// Parts of speech recognized by the surname model and declension rules.
enum WordClass { noun, adjective }

/// The three name fields to which a rule can be restricted.
enum ApplicationType { givenName, patronymicName, familyName }

/// Copies case by UTF-16 position, repeating the final template code unit.
String copyLetterCase(String template, String target) {
  if (target.isEmpty) return target;
  if (template.isEmpty) {
    throw StateError('Cannot copy letter case from an empty template.');
  }
  final result = StringBuffer();
  for (var i = 0; i < target.length; i++) {
    final source = template[i < template.length ? i : template.length - 1];
    final letter = target[i];
    result.write(
      source == source.toLowerCase()
          ? letter.toLowerCase()
          : source == source.toUpperCase()
          ? letter.toUpperCase()
          : letter,
    );
  }
  return result.toString();
}
