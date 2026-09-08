import 'dart:convert';
import 'dart:io';

/// Verify a local release example using an isolated, temporary Chrome profile.
Future<void> main(List<String> args) async {
  if (args.length != 1) throw ArgumentError('Pass one loopback example URL');
  final url = Uri.parse(args.single);
  if (url.scheme != 'http' ||
      url.host != '127.0.0.1' ||
      url.userInfo.isNotEmpty) {
    throw ArgumentError('Pass an HTTP loopback example URL');
  }
  final smokeUrl = url.replace(
    queryParameters: {...url.queryParameters, 'smoke': 'true'},
  );
  final root = Directory('tmp/browser-smoke')..createSync(recursive: true);
  final profile = root.createTempSync('chrome-').absolute;
  final chrome =
      Platform.environment['CHROME_EXECUTABLE'] ??
      (Platform.isWindows
          ? 'C:/Program Files/Google/Chrome/Application/chrome.exe'
          : 'google-chrome');
  final process = await Process.start(chrome, [
    '--headless',
    '--disable-gpu',
    '--no-first-run',
    '--disable-background-networking',
    '--user-data-dir=${profile.path}',
    '--dump-dom',
    '--virtual-time-budget=30000',
    '$smokeUrl',
  ]);
  final page = process.stdout.transform(utf8.decoder).join();
  final diagnostics = process.stderr.transform(utf8.decoder).join();
  var passed = false;
  try {
    final results = await Future.wait<Object>([
      process.exitCode,
      page,
      diagnostics,
    ]).timeout(const Duration(seconds: 60));
    File('${profile.path}/page.html').writeAsStringSync(results[1] as String);
    File('${profile.path}/chrome.log').writeAsStringSync(results[2] as String);
    final html = results[1] as String;
    final ready =
        html.contains('data-smoke="passed"') || html.contains('<flutter-view');
    if (results[0] != 0 || !ready) {
      throw StateError('Browser smoke failed; diagnostics: ${profile.path}');
    }
    passed = true;
    stdout.writeln('PASS: $url');
  } finally {
    process.kill();
    if (passed) {
      try {
        profile.deleteSync(recursive: true);
      } on FileSystemException {
        // Chrome can briefly retain profile files after it exits.
      }
    }
  }
}
