import 'dart:io';

/// Checks tracked files and untracked files that are not ignored.
Future<void> main() async {
  final result = await Process.run('git', [
    'ls-files',
    '--cached',
    '--others',
    '--exclude-standard',
  ]);
  if (result.exitCode != 0) throw StateError('${result.stderr}');
  final forbidden = RegExp(
    r'\.(?:[cm]?[jt]sx?|log|tmp|bak)$',
    caseSensitive: false,
  );
  final invalid = (result.stdout as String)
      .split('\n')
      .map((s) => s.trim())
      .where(
        (file) =>
            file.isNotEmpty &&
            (forbidden.hasMatch(file) ||
                file.startsWith('tmp/') ||
                file.contains('/node_modules/') ||
                file.endsWith('-report.json') ||
                (file.startsWith('doc/') && !file.endsWith('.md'))),
      )
      .toList();
  if (invalid.isNotEmpty) {
    throw StateError('Files must stay outside Git:\n${invalid.join('\n')}');
  }
  stdout.writeln('Repository file policy passed.');
}
