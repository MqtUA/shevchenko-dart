import 'dart:io';

/// Small loopback-only static server for the browser example.
Future<void> main(List<String> args) async {
  if (args.isEmpty || args.length > 2) {
    throw ArgumentError('Usage: dart run tool/serve.dart DIRECTORY [PORT]');
  }
  final root = Directory(args.first).resolveSymbolicLinksSync();
  final server = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    args.length == 2 ? int.parse(args[1]) : 8080,
  );
  stdout.writeln('Serving $root at http://127.0.0.1:${server.port}/');
  await for (final request in server) {
    try {
      final segments = request.uri.pathSegments;
      if (segments.any(
        (s) => s == '..' || s.contains('/') || s.contains('\\'),
      )) {
        request.response.statusCode = HttpStatus.forbidden;
      } else {
        final relative = request.uri.path.endsWith('/')
            ? '${segments.join('/')}index.html'
            : segments.join('/');
        final file = File('$root/$relative');
        if (!file.existsSync()) {
          request.response.statusCode = HttpStatus.notFound;
        } else if (!file.resolveSymbolicLinksSync().startsWith(
          '$root${Platform.pathSeparator}',
        )) {
          request.response.statusCode = HttpStatus.forbidden;
        } else {
          final extension = file.path.split('.').last;
          final types = {
            'html': 'text/html',
            'js': 'text/javascript',
            'mjs': 'text/javascript',
            'css': 'text/css',
            'json': 'application/json',
            'wasm': 'application/wasm',
            'png': 'image/png',
            'ico': 'image/x-icon',
          };
          request.response.headers.set(
            HttpHeaders.contentTypeHeader,
            types[extension] ?? 'application/octet-stream',
          );
          await request.response.addStream(file.openRead());
        }
      }
    } on FileSystemException {
      request.response.statusCode = HttpStatus.notFound;
    } finally {
      await request.response.close();
    }
  }
}
