import 'package:test/test.dart';

import 'full_runner.dart' as runner;

void main() {
  test(
    'full classifier and 1,418,228 public calls match the CPU oracle',
    runner.main,
    timeout: const Timeout(Duration(minutes: 30)),
  );
}
