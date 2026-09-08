import 'dart:io';

Future<void> main() async {
  final toolFiles =
      Directory('tool')
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .map((file) => file.path)
          .toList()
        ..sort();
  final result = await Process.start(Platform.resolvedExecutable, [
    'format',
    '--output=none',
    '--set-exit-if-changed',
    'lib',
    'test',
    'benchmark',
    'example/main.dart',
    'example/web_app/web/main.dart',
    ...toolFiles,
  ], mode: ProcessStartMode.inheritStdio);
  exitCode = await result.exitCode;
}
