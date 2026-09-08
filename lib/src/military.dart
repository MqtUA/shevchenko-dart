import 'declension.dart';
import 'extensions.dart';
import 'generated/data.dart';
import 'language.dart';

/// Built-in factory, useful for registering military support on a core instance.
ShevchenkoExtension militaryExtension(ExtensionContext context) {
  final inflector = _MilitaryInflector(context.wordInflector);
  return ShevchenkoExtension(
    fieldNames: ['militaryRank', 'militaryAppointment'],
    afterInflect: (grammaticalCase, input) async {
      final result = <String, Object?>{};
      for (final field in ['militaryRank', 'militaryAppointment']) {
        final value = input[field];
        if (value is String) {
          result[field] = await inflector.inflect(
            value,
            grammaticalCase,
            field,
          );
        }
      }
      return result;
    },
  );
}

final class _MilitaryInflector {
  _MilitaryInflector(this.words);
  final WordInflector words;
  bool _matches(Map<String, Object> rule, String word) =>
      (rule['include']! as List<String>).every(
        (p) => RegExp(p, caseSensitive: false).hasMatch(word),
      );

  Future<String> inflect(
    String value,
    GrammaticalCase grammaticalCase,
    String field,
  ) async {
    final output = <String>[];
    for (final token in value.split(' ')) {
      final hyphenated = militaryHyphenationRules.any(
        (rule) =>
            (rule['useCase'] == null || rule['useCase'] == field) &&
            _matches(rule, token),
      );
      final parts = <String>[];
      for (final part in hyphenated ? token.split('-') : [token]) {
        parts.add(await _word(part, grammaticalCase));
      }
      output.add(parts.join('-'));
    }
    return output.join(' ');
  }

  Future<String> _word(String original, GrammaticalCase grammaticalCase) async {
    var word = original;
    var start = '';
    var end = '';
    final leading = RegExp(r'''^(["'()])+''').firstMatch(word);
    if (leading != null) {
      start = leading[0]!;
      // Preserve upstream's one-code-unit slice even for multiple delimiters.
      word = word.substring(leading.start + 1);
    }
    final trailing = RegExp(r'''(["'()])+$''').firstMatch(word);
    if (trailing != null) {
      end = trailing[0]!;
      word = word.substring(0, trailing.start);
    }
    for (final rule in militaryClassifierRules) {
      if (_matches(rule, word)) {
        return start +
            await words.inflect(
              word,
              DeclensionParams(
                grammaticalCase: grammaticalCase,
                gender: GrammaticalGender.values.byName(
                  rule['gender']! as String,
                ),
                wordClass: WordClass.values.byName(
                  rule['wordClass']! as String,
                ),
              ),
            ) +
            end;
      }
    }
    return original;
  }
}
