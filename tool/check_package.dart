import 'dart:convert';
import 'dart:io';

/// Runs package validation and rejects unexpected warnings.
Future<void> main() async {
  final result = await Process.run(
    Platform.resolvedExecutable,
    ['pub', 'publish', '--dry-run', '--ignore-warnings'],
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  final output = '${result.stdout}\n${result.stderr}';
  stdout.write(output);
  const knownWarnings = [
    '* It\'s strongly recommended to include a "homepage" or "repository" field in your pubspec.yaml',
  ];
  final unexpected = output
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'\x1b\[[0-9;]*m'), '').trim())
      .where((line) => line.startsWith('* ') && !knownWarnings.contains(line))
      .toList();
  if (result.exitCode != 0 || unexpected.isNotEmpty) {
    stderr.writeln('Package validation failed: ${unexpected.join('\n')}');
    exitCode = 1;
  }
}
