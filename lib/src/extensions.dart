import 'dart:async';

import 'declension.dart';
import 'language.dart';

/// Hooks receive normalized input and run sequentially; later outputs win.
typedef AfterInflectHook =
    FutureOr<Map<String, Object?>?> Function(
      GrammaticalCase grammaticalCase,
      Map<String, Object?> input,
    );
typedef ExtensionFactory =
    ShevchenkoExtension Function(ExtensionContext context);

final class ExtensionContext {
  const ExtensionContext({required this.wordInflector});
  final WordInflector wordInflector;
}

final class ShevchenkoExtension {
  ShevchenkoExtension({required Iterable<String> fieldNames, this.afterInflect})
    : fieldNames = List.unmodifiable(fieldNames);
  final List<String> fieldNames;
  final AfterInflectHook? afterInflect;
}
