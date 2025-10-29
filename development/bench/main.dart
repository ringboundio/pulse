import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'benchmark.dart';
import 'buffer_bench.dart';
import 'chart_bench.dart';
import 'input_bench.dart';

const Duration _defaultMinRunTime = Duration(milliseconds: 600);

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  const BenchmarkConfig config = BenchmarkConfig(
    minRunTime: _defaultMinRunTime,
    warmupDuration: Duration(milliseconds: 350),
    warmupIterations: 1,
    forceGCBeforeRun: true,
  );
  final BenchmarkRunner runner = BenchmarkRunner(config: config);

  final List<BenchmarkDefinition> benchmarks = <BenchmarkDefinition>[
    ...buildChartBenchmarks(),
    ...buildBufferBenchmarks(),
    ...buildInputBenchmarks(),
  ];

  const String warmupMessage =
      'Starting benchmarks... this may take a few moments while we gather '
      'stable measurements.';
  stdout.writeln('\x1B[93m$warmupMessage\x1B[0m');

  final List<BenchmarkResult> results = <BenchmarkResult>[];
  for (final BenchmarkDefinition benchmark in benchmarks) {
    final BenchmarkResult result = await runner.run(benchmark);
    results.add(result);
  }

  _printReport(results);
  drainBlackHole();
  exit(0);
}

void _printReport(List<BenchmarkResult> results) {
  if (results.isEmpty) {
    stdout.writeln('No benchmarks were executed.');
    return;
  }

  results.sort((BenchmarkResult a, BenchmarkResult b) {
    final double nsPerOpA = a.nsPerOp;
    final double nsPerOpB = b.nsPerOp;
    if (nsPerOpA == nsPerOpB) {
      return a.benchmark.name.compareTo(b.benchmark.name);
    }
    return nsPerOpB.compareTo(nsPerOpA);
  });

  const int nameWidth = 36;
  const int iterationsWidth = 10;
  const int totalWidth = 10;
  const int nsPerOpWidth = 12;
  const int allocPerOpWidth = 12;
  const int opsPerSecondWidth = 12;
  const int fpsWidth = 10;

  String repeat(String char, int width) {
    return List<String>.filled(width, char).join();
  }

  String separator() {
    return '+-${repeat('-', nameWidth)}-+-${repeat('-', iterationsWidth)}-+-${repeat('-', totalWidth)}-+-${repeat('-', nsPerOpWidth)}-+-${repeat('-', allocPerOpWidth)}-+-${repeat('-', opsPerSecondWidth)}-+-${repeat('-', fpsWidth)}-+';
  }

  String cell(String value, int width, {bool right = false}) {
    final String clamped = value.length > width
        ? value.substring(0, width)
        : value;
    return right ? clamped.padLeft(width) : clamped.padRight(width);
  }

  stdout.writeln();
  stdout.writeln(separator());
  stdout.writeln(
    '| ${cell('benchmark', nameWidth)} '
    '| ${cell('iterations', iterationsWidth, right: true)} '
    '| ${cell('total', totalWidth, right: true)} '
    '| ${cell('ns/op', nsPerOpWidth, right: true)} '
    '| ${cell('alloc/op', allocPerOpWidth, right: true)} '
    '| ${cell('ops/s', opsPerSecondWidth, right: true)} '
    '| ${cell('fps', fpsWidth, right: true)} |',
  );
  stdout.writeln(separator());

  for (final BenchmarkResult result in results) {
    final double opsPerSecondValue = result.opsPerSecond;
    final bool isFrame = result.benchmark.tags.contains('frame');
    final String fpsValue = isFrame && opsPerSecondValue.isFinite
        ? opsPerSecondValue.toStringAsFixed(1)
        : '';
    final String totalFormatted = _formatDuration(result.elapsed);
    final double? bytesPerOp = result.bytesPerOp;
    final String allocValue = bytesPerOp == null
        ? ''
        : _formatBytes(bytesPerOp);

    stdout.writeln(
      '| ${cell(result.benchmark.name, nameWidth)} '
      '| ${cell(result.iterations.toString(), iterationsWidth, right: true)} '
      '| ${cell(totalFormatted, totalWidth, right: true)} '
      '| ${cell(result.nsPerOp.toStringAsFixed(1), nsPerOpWidth, right: true)} '
      '| ${cell(allocValue, allocPerOpWidth, right: true)} '
      '| ${cell(opsPerSecondValue.isFinite ? opsPerSecondValue.toStringAsFixed(0) : 'inf', opsPerSecondWidth, right: true)} '
      '| ${cell(fpsValue, fpsWidth, right: true)} |',
    );
  }

  stdout.writeln(separator());
}

String _formatDuration(Duration duration) {
  final int microseconds = duration.inMicroseconds;
  if (microseconds >= 1000000) {
    final double seconds = microseconds / 1000000;
    return '${seconds.toStringAsFixed(2)}s';
  }
  if (microseconds >= 1000) {
    final double milliseconds = microseconds / 1000;
    return '${milliseconds.toStringAsFixed(2)}ms';
  }
  return '${microseconds}us';
}

String _formatBytes(double bytes) {
  if (bytes.isNaN || bytes.isInfinite) {
    return '';
  }
  final double absolute = bytes.abs();
  double value = absolute;
  String unit = 'B';
  const double kb = 1024;
  const double mb = kb * 1024;
  const double gb = mb * 1024;

  if (absolute >= gb) {
    value = absolute / gb;
    unit = 'GB';
  } else if (absolute >= mb) {
    value = absolute / mb;
    unit = 'MB';
  } else if (absolute >= kb) {
    value = absolute / kb;
    unit = 'KB';
  }

  final int precision = value >= 100
      ? 0
      : value >= 10
      ? 1
      : 2;
  final String formatted = value.toStringAsFixed(precision);
  return absolute == 0 ? '0B' : '$formatted$unit';
}
