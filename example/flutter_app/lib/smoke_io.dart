import 'dart:convert';
import 'dart:io';

void finishSmoke(Map<String, Object?> result) {
  final file = File(
    Platform.environment['SHEVCHENKO_SMOKE_REPORT'] ?? 'tmp/smoke-result.json',
  );
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(jsonEncode({'status': 'passed', 'output': result}));
  exit(0);
}
