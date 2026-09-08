import 'dart:convert';
import 'dart:io';

/// Runs package validation and fails when the archive cannot be produced.
Future<void> main() async {
  final result = await Process.run(
    Platform.resolvedExecutable,
    ['pub', 'publish', '--dry-run', '--ignore-warnings'],
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  final output = '${result.stdout}\n${result.stderr}';
  stdout.write(output);
  if (result.exitCode != 0) {
    stderr.writeln('Package validation failed.');
    exitCode = 1;
  }
}
