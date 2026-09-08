import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:shevchenko/shevchenko.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

const _sampleCalls = 1000;
const _plateauSeries = 8;
const _plateauCallsPerSeries = 10000;
const _buildMode = String.fromEnvironment(
  'BENCHMARK_MODE',
  defaultValue: 'jit',
);

Future<void> main(List<String> arguments) async {
  final outputPath = _parseOutputPath(arguments);
  final metrics = await _VmMetrics.connect();
  try {
    final engine = Shevchenko();
    final inputs = <String, DeclensionInput>{
      'namesWithoutModel': const DeclensionInput(
        gender: GrammaticalGender.masculine,
        givenName: 'Тарас',
        patronymicName: 'Григорович',
        familyName: 'Шевченко',
      ),
      'surnameModel': const DeclensionInput(
        gender: GrammaticalGender.feminine,
        familyName: 'Зелена',
      ),
      'rank': const DeclensionInput(
        gender: GrammaticalGender.masculine,
        militaryRank: 'старший солдат',
      ),
      'appointment': const DeclensionInput(
        gender: GrammaticalGender.masculine,
        militaryAppointment:
            'старший помічник начальника відділення підготовки особового складу',
      ),
      'combined': const DeclensionInput(
        gender: GrammaticalGender.masculine,
        givenName: 'Тарас',
        patronymicName: 'Григорович',
        familyName: 'Шевченко',
        militaryRank: 'солдат',
        militaryAppointment: 'помічник гранатометника',
      ),
    };

    final rssBefore = ProcessInfo.currentRss;
    final cold = Stopwatch()..start();
    await engine.inGenitive(inputs['surnameModel']!);
    cold.stop();

    final report = <String, Object?>{
      'sdk': Platform.version,
      'os': Platform.operatingSystem,
      'buildMode': _buildMode,
      'vmServiceMetricsAvailable': metrics != null,
      'coldFirstModelMicroseconds': cold.elapsedMicroseconds,
      'rssBeforeBytes': rssBefore,
      'scenarios': <String, Object?>{},
    };
    final scenarios = report['scenarios']! as Map<String, Object?>;

    for (final entry in inputs.entries) {
      for (var i = 0; i < 100; i++) {
        await engine.inGenitive(entry.value);
      }

      final samples = <int>[];
      final timer = Stopwatch();
      for (var i = 0; i < _sampleCalls; i++) {
        timer
          ..reset()
          ..start();
        await engine.inGenitive(entry.value);
        timer.stop();
        samples.add(timer.elapsedMicroseconds);
      }
      samples.sort();

      final stringInputs = entry.value
          .toJson()
          .values
          .whereType<String>()
          .toList();
      final scenario = <String, Object?>{
        'calls': _sampleCalls,
        'medianMicroseconds': _percentile(samples, 0.50),
        'p95Microseconds': _percentile(samples, 0.95),
        'inputFields': stringInputs.length,
        'inputCodeUnits': stringInputs.fold<int>(
          0,
          (sum, value) => sum + value.length,
        ),
        'inputWords': stringInputs.fold<int>(0, (sum, value) {
          return sum + value.trim().split(RegExp(r'\s+')).length;
        }),
      };

      if (metrics != null) {
        await metrics.resetAllocations();
        await _runCalls(engine, entry.value, _sampleCalls);
        scenario.addAll(await metrics.readAllocations());
      }
      scenarios[entry.key] = scenario;
    }

    final memorySeries = <Map<String, Object?>>[];
    for (var series = 1; series <= _plateauSeries; series++) {
      final elapsed = Stopwatch()..start();
      await _runCalls(engine, inputs['combined']!, _plateauCallsPerSeries);
      elapsed.stop();
      final snapshot = <String, Object?>{
        'series': series,
        'calls': _plateauCallsPerSeries,
        'elapsedMilliseconds': elapsed.elapsedMilliseconds,
        'rssBytes': ProcessInfo.currentRss,
      };
      if (metrics != null) {
        snapshot.addAll(await metrics.readMemoryAfterGc());
      }
      memorySeries.add(snapshot);
    }

    report['memorySeries'] = memorySeries;
    report['memoryPlateau'] = _plateauSummary(memorySeries);
    report['rssAfterBytes'] = ProcessInfo.currentRss;
    report['peakRssBytes'] = ProcessInfo.maxRss;
    final encoded = const JsonEncoder.withIndent(' ').convert(report);
    if (outputPath == null) {
      stdout.writeln(encoded);
    } else {
      File(outputPath).writeAsStringSync('$encoded\n');
    }
  } finally {
    await metrics?.close();
  }
}

String? _parseOutputPath(List<String> arguments) {
  if (arguments.isEmpty) return null;
  if (arguments.length == 1 && arguments.single.startsWith('--output=')) {
    final path = arguments.single.substring('--output='.length);
    if (path.isNotEmpty) return path;
  }
  throw const FormatException('Usage: benchmark/main.dart [--output=<path>]');
}

Future<void> _runCalls(
  Shevchenko engine,
  DeclensionInput input,
  int calls,
) async {
  for (var i = 0; i < calls; i++) {
    await engine.inGenitive(input);
  }
}

int _percentile(List<int> sortedSamples, double percentile) {
  final index = ((sortedSamples.length - 1) * percentile).round();
  return sortedSamples[index];
}

Map<String, Object?> _plateauSummary(List<Map<String, Object?>> series) {
  const tailLength = 3;
  final tail = series.skip(series.length - tailLength).toList();
  final rss = tail.map((sample) => sample['rssBytes']! as int).toList();
  final summary = <String, Object?>{
    'series': _plateauSeries,
    'callsPerSeries': _plateauCallsPerSeries,
    'tailSeries': tailLength,
    'rssTailRangeBytes': _range(rss),
    'rssGrowthFirstToLastBytes':
        (series.last['rssBytes']! as int) - (series.first['rssBytes']! as int),
  };
  if (tail.every((sample) => sample.containsKey('heapUsageBytes'))) {
    final heap = tail
        .map((sample) => sample['heapUsageBytes']! as int)
        .toList();
    summary['heapUsageTailRangeBytes'] = _range(heap);
    summary['heapUsageGrowthFirstToLastBytes'] =
        (series.last['heapUsageBytes']! as int) -
        (series.first['heapUsageBytes']! as int);
  }
  return summary;
}

int _range(List<int> values) {
  var minimum = values.first;
  var maximum = values.first;
  for (final value in values.skip(1)) {
    if (value < minimum) minimum = value;
    if (value > maximum) maximum = value;
  }
  return maximum - minimum;
}

final class _VmMetrics {
  _VmMetrics(this._service, this._isolateId);

  final VmService _service;
  final String _isolateId;

  static Future<_VmMetrics?> connect() async {
    final serverUri = (await developer.Service.getInfo()).serverUri;
    if (serverUri == null) return null;

    final webSocketUri = serverUri.replace(
      scheme: serverUri.scheme == 'https' ? 'wss' : 'ws',
      path: '${serverUri.path}ws',
    );
    final service = await vmServiceConnectUri(webSocketUri.toString());
    final vm = await service.getVM();
    final isolates = vm.isolates ?? const <IsolateRef>[];
    if (isolates.isEmpty) {
      await service.dispose();
      throw StateError('VM service returned no isolates.');
    }
    final mainIsolates = isolates.where((value) => value.name == 'main');
    final isolate = mainIsolates.isEmpty ? isolates.first : mainIsolates.first;
    return _VmMetrics(service, isolate.id!);
  }

  Future<void> resetAllocations() async {
    await _service.getAllocationProfile(_isolateId, reset: true, gc: true);
  }

  Future<Map<String, Object?>> readAllocations() async {
    final profile = await _service.getAllocationProfile(_isolateId);
    var instances = 0;
    var bytes = 0;
    for (final member in profile.members ?? const <ClassHeapStats>[]) {
      instances += member.instancesAccumulated ?? 0;
      bytes += member.accumulatedSize ?? 0;
    }
    return {
      'allocationSampleCalls': _sampleCalls,
      'allocatedInstances': instances,
      'allocatedBytes': bytes,
    };
  }

  Future<Map<String, Object?>> readMemoryAfterGc() async {
    final profile = await _service.getAllocationProfile(_isolateId, gc: true);
    final memory = profile.memoryUsage;
    return {
      'heapUsageBytes': memory?.heapUsage ?? 0,
      'heapCapacityBytes': memory?.heapCapacity ?? 0,
      'externalUsageBytes': memory?.externalUsage ?? 0,
    };
  }

  Future<void> close() => _service.dispose();
}
