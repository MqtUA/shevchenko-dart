import 'dart:convert';
import 'dart:io';

void main(List<String> arguments) {
  if (arguments.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/size_report.dart '
      '<publish-dry-run.txt> <browser.js> <aot-executable>',
    );
    exitCode = 64;
    return;
  }

  final publishReport = File(arguments[0]).readAsStringSync();
  final sizeMatch = RegExp(
    r'Total compressed archive size:\s*(\d+(?:\.\d+)?\s+[KMGT]?B)',
  ).firstMatch(publishReport);
  if (sizeMatch == null) {
    stderr.writeln('Package size was not found in the publish dry-run output.');
    exitCode = 1;
    return;
  }

  final browserBytes = File(arguments[1]).readAsBytesSync();
  final report = {
    'packageDryRunReportedSize': sizeMatch.group(1),
    'browserJavaScriptBytes': browserBytes.length,
    'browserJavaScriptGzipBytes': gzip.encode(browserBytes).length,
    'aotExecutableBytes': File(arguments[2]).lengthSync(),
  };
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
}
