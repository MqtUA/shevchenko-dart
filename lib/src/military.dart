import 'declension.dart';
import 'extensions.dart';
import 'generated/data.dart';
import 'language.dart';

const _militaryFields = ['militaryRank', 'militaryAppointment'];

/// Built-in factory, useful for registering military support on a core instance.
ShevchenkoExtension militaryExtension(ExtensionContext context) {
  final inflector = _MilitaryInflector(context.wordInflector);
  return ShevchenkoExtension(
    fieldNames: _militaryFields,
    afterInflect: (grammaticalCase, input) async {
      final result = <String, Object?>{};
      for (final field in _militaryFields) {
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

List<RegExp> _compilePatterns(Object? patterns) => List.unmodifiable(
  (patterns! as List).map(
    (pattern) => RegExp(pattern as String, caseSensitive: false),
  ),
);

bool _matchesAll(List<RegExp> patterns, String word) =>
    patterns.every((pattern) => pattern.hasMatch(word));

typedef _HyphenationRule = ({List<RegExp> include, String? field});
typedef _ClassifierRule = ({
  List<RegExp> include,
  GrammaticalGender gender,
  WordClass wordClass,
});

final _hyphenationRules = List<_HyphenationRule>.unmodifiable(
  militaryHyphenationRules.map(
    (rule) => (
      include: _compilePatterns(rule['include']),
      field: rule['useCase'] as String?,
    ),
  ),
);

final _classifierRules = List<_ClassifierRule>.unmodifiable(
  militaryClassifierRules.map(
    (rule) => (
      include: _compilePatterns(rule['include']),
      gender: GrammaticalGender.values.byName(rule['gender']! as String),
      wordClass: WordClass.values.byName(rule['wordClass']! as String),
    ),
  ),
);

final _leadingDelimiters = RegExp(r'''^(["'()])+''');
final _trailingDelimiters = RegExp(r'''(["'()])+$''');

final class _MilitaryInflector {
  _MilitaryInflector(this._words);
  final WordInflector _words;

  Future<String> inflect(
    String value,
    GrammaticalCase grammaticalCase,
    String field,
  ) async {
    final output = <String>[];
    for (final token in value.split(' ')) {
      final hyphenated = _hyphenationRules.any(
        (rule) =>
            (rule.field == null || rule.field == field) &&
            _matchesAll(rule.include, token),
      );
      final parts = <String>[];
      for (final part in hyphenated ? token.split('-') : [token]) {
        parts.add(await _inflectWord(part, grammaticalCase));
      }
      output.add(parts.join('-'));
    }
    return output.join(' ');
  }

  Future<String> _inflectWord(
    String original,
    GrammaticalCase grammaticalCase,
  ) async {
    var word = original;
    var start = '';
    var end = '';
    final leading = _leadingDelimiters.firstMatch(word);
    if (leading != null) {
      start = leading[0]!;
      // Upstream strips only one code unit, even for repeated delimiters.
      word = word.substring(leading.start + 1);
    }
    final trailing = _trailingDelimiters.firstMatch(word);
    if (trailing != null) {
      end = trailing[0]!;
      word = word.substring(0, trailing.start);
    }
    for (final rule in _classifierRules) {
      if (_matchesAll(rule.include, word)) {
        final inflected = await _words.inflect(
          word,
          DeclensionParams(
            grammaticalCase: grammaticalCase,
            gender: rule.gender,
            wordClass: rule.wordClass,
          ),
        );
        return '$start$inflected$end';
      }
    }
    return original;
  }
}
