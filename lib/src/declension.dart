import 'language.dart';

enum InflectionCommandAction { append, replace }

/// Explains how a single word was resolved by [WordInflector].
enum WordInflectionStatus {
  /// A rule matched and changed the word.
  changed,

  /// A rule matched but its selected form is identical to the input.
  unchanged,

  /// The engine intentionally preserved the word before rule selection.
  preserved,

  /// No rule passed the configured filters.
  noMatchingRule,
}

/// The declined value and rule-selection details for one word.
final class WordInflectionResult {
  const WordInflectionResult({
    required this.input,
    required this.value,
    required this.status,
    this.ruleDescription,
    this.alternativeCount = 0,
  });

  /// The word supplied to the inflector.
  final String input;

  /// The selected declined form.
  final String value;

  /// Whether and how a rule affected the word.
  final WordInflectionStatus status;

  /// The description of the selected rule, when one matched.
  final String? ruleDescription;

  /// The number of forms stored by the selected rule for this case.
  final int alternativeCount;
}

/// A command addresses a capture group, with zero denoting the first group.
final class InflectionCommand {
  const InflectionCommand({required this.action, required this.value});
  final InflectionCommandAction action;
  final String value;
}

final class DeclensionPattern {
  const DeclensionPattern({required this.find, required this.modify});
  final String find;
  final String modify;
}

/// An immutable rule. Alternatives are preserved; only the first is executed.
final class DeclensionRule {
  DeclensionRule({
    this.description = '',
    Iterable<String> examples = const [],
    required this.wordClass,
    required Iterable<GrammaticalGender> gender,
    required this.priority,
    Iterable<ApplicationType> applicationType = const [],
    required this.pattern,
    required Map<GrammaticalCase, List<Map<int, InflectionCommand>>>
    grammaticalCases,
  }) : _find = RegExp(pattern.find, caseSensitive: false),
       _modify = RegExp(pattern.modify, caseSensitive: false),
       examples = List.unmodifiable(examples),
       gender = List.unmodifiable(gender),
       applicationType = List.unmodifiable(applicationType),
       grammaticalCases = Map.unmodifiable(
         grammaticalCases.map(
           (key, value) => MapEntry(
             key,
             List<Map<int, InflectionCommand>>.unmodifiable(
               value.map(
                 (commands) =>
                     Map<int, InflectionCommand>.unmodifiable(commands),
               ),
             ),
           ),
         ),
       ) {
    for (final value in GrammaticalCase.values) {
      if (!this.grammaticalCases.containsKey(value)) {
        throw ArgumentError('Missing grammatical case: ${value.name}');
      }
    }
  }
  factory DeclensionRule.fromJson(Map<String, Object?> json) {
    final pattern = (json['pattern'] as Map).cast<String, String>();
    final cases = (json['grammaticalCases'] as Map).cast<String, List>();
    return DeclensionRule(
      description: json['description'] as String,
      examples: (json['examples'] as List).cast<String>(),
      wordClass: WordClass.values.byName(json['wordClass'] as String),
      gender: (json['gender'] as List).cast<String>().map(
        GrammaticalGender.values.byName,
      ),
      priority: json['priority'] as int,
      applicationType: (json['applicationType'] as List).cast<String>().map(
        ApplicationType.values.byName,
      ),
      pattern: DeclensionPattern(
        find: pattern['find']!,
        modify: pattern['modify']!,
      ),
      grammaticalCases: cases.map(
        (key, alternatives) => MapEntry(
          GrammaticalCase.values.byName(key),
          alternatives
              .map(
                (alternative) => (alternative as Map).map((index, raw) {
                  final command = (raw as Map).cast<String, String>();
                  return MapEntry(
                    int.parse(index as String),
                    InflectionCommand(
                      action: InflectionCommandAction.values.byName(
                        command['action']!,
                      ),
                      value: command['value']!,
                    ),
                  );
                }),
              )
              .toList(),
        ),
      ),
    );
  }
  final String description;
  final List<String> examples;
  final WordClass wordClass;
  final List<GrammaticalGender> gender;
  final int priority;
  final List<ApplicationType> applicationType;
  final DeclensionPattern pattern;
  final RegExp _find;
  final RegExp _modify;
  final Map<GrammaticalCase, List<Map<int, InflectionCommand>>>
  grammaticalCases;
}

typedef CustomRuleFilter =
    bool Function(DeclensionRule rule, int index, List<DeclensionRule> rules);

final class DeclensionParams {
  const DeclensionParams({
    required this.grammaticalCase,
    required this.gender,
    this.wordClass,
    this.applicationType,
    this.customRuleFilter,
  });
  final GrammaticalCase grammaticalCase;
  final GrammaticalGender gender;
  final WordClass? wordClass;
  final ApplicationType? applicationType;
  final CustomRuleFilter? customRuleFilter;
}

/// Executes ordered rules without public-input normalization.
final class WordInflector {
  WordInflector(Iterable<DeclensionRule> rules) {
    final indexed = rules.indexed.toList()
      ..sort((a, b) {
        final priority = b.$2.priority.compareTo(a.$2.priority);
        return priority != 0 ? priority : a.$1.compareTo(b.$1);
      });
    _rules = List.unmodifiable(indexed.map((entry) => entry.$2));
  }
  late final List<DeclensionRule> _rules;

  Future<String> inflect(String word, DeclensionParams params) async {
    final rule = _selectRule(word, params);
    if (rule == null) return word;
    final alternatives = rule.grammaticalCases[params.grammaticalCase]!;
    return alternatives.isEmpty ? word : _apply(word, rule, alternatives.first);
  }

  /// Inflects [word] and reports which rule produced the selected form.
  Future<WordInflectionResult> inflectWithDiagnostics(
    String word,
    DeclensionParams params,
  ) async {
    final rule = _selectRule(word, params);
    if (rule == null) {
      return WordInflectionResult(
        input: word,
        value: word,
        status: WordInflectionStatus.noMatchingRule,
      );
    }
    final alternatives = rule.grammaticalCases[params.grammaticalCase]!;
    if (alternatives.isEmpty) {
      return WordInflectionResult(
        input: word,
        value: word,
        status: WordInflectionStatus.unchanged,
        ruleDescription: rule.description,
      );
    }
    final value = _apply(word, rule, alternatives.first);
    return WordInflectionResult(
      input: word,
      value: value,
      status: value == word
          ? WordInflectionStatus.unchanged
          : WordInflectionStatus.changed,
      ruleDescription: rule.description,
      alternativeCount: alternatives.length,
    );
  }

  DeclensionRule? _selectRule(String word, DeclensionParams params) {
    bool matches(DeclensionRule rule) =>
        rule.gender.contains(params.gender) &&
        (params.applicationType == null ||
            rule.applicationType.isEmpty ||
            rule.applicationType.contains(params.applicationType)) &&
        rule._find.hasMatch(word) &&
        (params.wordClass == null || rule.wordClass == params.wordClass);

    final filter = params.customRuleFilter;
    if (filter == null) {
      for (final rule in _rules) {
        if (matches(rule)) return rule;
      }
      return null;
    }
    final candidates = List<DeclensionRule>.unmodifiable([
      for (final rule in _rules)
        if (matches(rule)) rule,
    ]);
    DeclensionRule? rule;
    // Every callback must run, even after the first rule has been selected.
    for (var i = 0; i < candidates.length; i++) {
      if (filter(candidates[i], i, candidates)) {
        rule ??= candidates[i];
      }
    }
    return rule;
  }

  String _apply(
    String word,
    DeclensionRule rule,
    Map<int, InflectionCommand> commands,
  ) {
    final result = word.replaceAllMapped(rule._modify, (match) {
      final replacement = StringBuffer();
      for (var i = 0; i < match.groupCount; i++) {
        // JS string concatenation coerces unmatched optional captures to 'undefined'.
        var value = match.group(i + 1) ?? 'undefined';
        final command = commands[i];
        if (command != null) {
          value = switch (command.action) {
            InflectionCommandAction.append => value + command.value,
            InflectionCommandAction.replace => command.value,
          };
        }
        replacement.write(value);
      }
      return replacement.toString();
    });
    return copyLetterCase(word, result);
  }
}
