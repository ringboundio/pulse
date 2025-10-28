import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';

class BenchmarkConfig {
  const BenchmarkConfig({
    this.minIterations = 1,
    this.minRunTime = const Duration(milliseconds: 250),
    this.maxIterations = 1 << 32,
    this.warmupIterations = 1,
    this.warmupDuration = const Duration(milliseconds: 250),
    this.forceGCBeforeRun = true,
  }) : assert(minIterations > 0),
       assert(maxIterations >= minIterations),
       assert(warmupIterations >= 0);

  final int minIterations;
  final Duration minRunTime;
  final int maxIterations;
  final int warmupIterations;
  final Duration warmupDuration;
  final bool forceGCBeforeRun;
}

typedef BenchmarkSetup = FutureOr<void> Function();
typedef BenchmarkTeardown = FutureOr<void> Function();
typedef BenchmarkBody = FutureOr<void> Function(int iteration);

typedef BenchmarkTag = String;

class BenchmarkDefinition {
  const BenchmarkDefinition({
    required this.name,
    required this.body,
    this.setup,
    this.teardown,
    this.tags = const <BenchmarkTag>[],
  });

  final String name;
  final BenchmarkBody body;
  final BenchmarkSetup? setup;
  final BenchmarkTeardown? teardown;
  final List<BenchmarkTag> tags;
}

class BenchmarkResult {
  const BenchmarkResult({
    required this.benchmark,
    required this.iterations,
    required this.elapsed,
  });

  final BenchmarkDefinition benchmark;
  final int iterations;
  final Duration elapsed;

  double get nsPerOp {
    final double micros = elapsed.inMicroseconds.toDouble();
    return (micros * 1000.0) / math.max(iterations, 1);
  }

  double get opsPerSecond {
    final double seconds = elapsed.inMicroseconds / 1e6;
    if (seconds == 0.0) {
      return double.infinity;
    }
    return iterations / seconds;
  }
}

class BenchmarkRunner {
  const BenchmarkRunner({this.config = const BenchmarkConfig()});

  final BenchmarkConfig config;

  Future<BenchmarkResult> run(BenchmarkDefinition benchmark) async {
    await _performWarmup(benchmark);
    await _triggerGCIfSupported();

    int iterations = math.max(config.minIterations, 1);
    Duration elapsed = Duration.zero;
    while (true) {
      await Future.sync(() => benchmark.setup?.call());
      final Stopwatch stopwatch = Stopwatch()..start();
      for (int i = 0; i < iterations; i += 1) {
        await Future.sync(() => benchmark.body(i));
      }
      stopwatch.stop();
      elapsed = stopwatch.elapsed;
      await Future.sync(() => benchmark.teardown?.call());

      if (elapsed >= config.minRunTime || iterations >= config.maxIterations) {
        break;
      }

      final int elapsedMicros = math.max(elapsed.inMicroseconds, 1);
      final double scale = config.minRunTime.inMicroseconds / elapsedMicros;
      final int proposed = (iterations * scale).ceil();
      iterations = math.min(
        math.max(iterations * 2, proposed),
        config.maxIterations,
      );
    }

    return BenchmarkResult(
      benchmark: benchmark,
      iterations: iterations,
      elapsed: elapsed,
    );
  }

  Future<void> _performWarmup(BenchmarkDefinition benchmark) async {
    final bool hasWarmupIterations = config.warmupIterations > 0;
    final bool hasWarmupDuration = config.warmupDuration > Duration.zero;
    if (!hasWarmupIterations && !hasWarmupDuration) {
      return;
    }

    int executedIterations = 0;
    Duration elapsed = Duration.zero;
    int loopIterations = hasWarmupIterations
        ? math.max(config.warmupIterations, 1)
        : math.max(config.minIterations, 1);

    while (true) {
      loopIterations = math.min(loopIterations, config.maxIterations);
      await Future.sync(() => benchmark.setup?.call());
      final Stopwatch stopwatch = Stopwatch()..start();
      for (int i = 0; i < loopIterations; i += 1) {
        await Future.sync(() => benchmark.body(i));
      }
      stopwatch.stop();
      elapsed += stopwatch.elapsed;
      executedIterations += loopIterations;
      await Future.sync(() => benchmark.teardown?.call());

      final bool iterationReady =
          !hasWarmupIterations || executedIterations >= config.warmupIterations;
      final bool durationReady =
          !hasWarmupDuration || elapsed >= config.warmupDuration;
      if (iterationReady && durationReady) {
        break;
      }

      if (loopIterations >= config.maxIterations) {
        break;
      }
      loopIterations = math.min(loopIterations * 2, config.maxIterations);
    }
  }

  Future<void> _triggerGCIfSupported() async {
    if (!config.forceGCBeforeRun) {
      return;
    }
    try {
      await SystemChannels.system.send('memoryPressure');
    } catch (_) {
      // Best effort GC; ignore failures when service is unavailable.
    }
  }
}

int _blackHoleAccumulator = 0;
Object? _blackHoleLastValue;

@pragma('vm:prefer-inline')
void blackHole(Object? value) {
  _blackHoleLastValue = value;
  if (value == null) {
    _blackHoleAccumulator ^= 0x9e3779b9;
    return;
  }
  if (value is num) {
    _blackHoleAccumulator ^= value.toInt();
    return;
  }
  if (value is bool) {
    _blackHoleAccumulator ^= value ? 0xace1 : 0xb4b82e39;
    return;
  }
  _blackHoleAccumulator ^= value.hashCode;
}

@pragma('vm:never-inline')
int drainBlackHole() {
  final int result =
      _blackHoleAccumulator ^ (_blackHoleLastValue?.hashCode ?? 0);
  _blackHoleAccumulator = 0;
  _blackHoleLastValue = null;
  return result;
}
