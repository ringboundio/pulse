import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

import 'package:pulse/buffer/channel.dart';
import 'package:pulse/buffer/sample_store.dart';
import 'package:pulse/buffer/worker.dart';

import 'benchmark.dart';
import 'dataset.dart';

List<BenchmarkDefinition> buildBufferBenchmarks() {
  final BufferBenchmarkDataset data = bufferBenchmarkDataset;
  final List<BufferSample> samples = data.samples;
  final BufferRange queryRange = data.queryRange;
  final BufferRange trimRetention = data.trimRange;
  final BufferPolicy policy = data.policy;
  final BufferSampleStore extractStore = data.createSampleStore();

  final _DatasetBufferProvider provider = _DatasetBufferProvider(samples);
  final Future<_BufferWorkerHarness> workerHarnessFuture =
      _BufferWorkerHarness.start(
        provider: provider,
        config: data.config,
        policy: policy,
      );

  final BufferRange haloRange = queryRange.expand(policy);
  final List<BufferSample> haloSamples = samples
      .where(
        (BufferSample sample) =>
            sample.epochMicros >= haloRange.startMicros &&
            sample.epochMicros < haloRange.endMicros,
      )
      .toList(growable: false);
  final BufferSamplesEvent samplesEvent = BufferSamplesEvent(
    window: queryRange,
    samples: haloSamples,
  );

  return <BenchmarkDefinition>[
    // Measures merging raw samples into a fresh store to monitor ingest costs.
    BenchmarkDefinition(
      name: 'buffer/sample_store_merge',
      body: (_) {
        final BufferSampleStore store = BufferSampleStore();
        store.merge(samples);
        blackHole(store);
      },
    ),
    // Extracts a window from a prepared store so we catch regressions in read
    // path filtering.
    BenchmarkDefinition(
      name: 'buffer/sample_store_extract',
      body: (_) {
        final BufferSampleSeries series = extractStore.extractSeries(
          queryRange,
        );
        blackHole(series.length);
      },
    ),
    // Exercises trim cycles to ensure eviction math stays efficient under
    // realistic retention settings.
    BenchmarkDefinition(
      name: 'buffer/sample_store_trim_cycle',
      body: (_) {
        final BufferSampleStore store = BufferSampleStore();
        store.merge(samples);
        store.trim(trimRetention.startMicros, trimRetention.endMicros);
        blackHole(store);
      },
    ),
    // Expands a query window with policy halos to monitor range arithmetic
    // overhead.
    BenchmarkDefinition(
      name: 'buffer/range_expand',
      body: (_) {
        final BufferRange expanded = queryRange.expand(policy);
        blackHole(expanded.endMicros - expanded.startMicros);
      },
    ),
    // Fetches samples through the worker harness to capture async range pulls
    // and isolate messaging.
    BenchmarkDefinition(
      name: 'buffer/worker_fetch_window',
      body: (_) async {
        final _BufferWorkerHarness harness = await workerHarnessFuture;
        final BufferSampleSeries series = await harness.requestRange(
          queryRange,
        );
        blackHole(series.length);
      },
    ),
    // Sends policy updates to the worker so we keep tabs on control-plane
    // messaging overhead.
    BenchmarkDefinition(
      name: 'buffer/worker_policy_update',
      body: (_) async {
        final _BufferWorkerHarness harness = await workerHarnessFuture;
        await harness.setPolicy(policy);
        blackHole(harness.generation);
      },
      teardown: () async {
        final _BufferWorkerHarness harness = await workerHarnessFuture;
        await harness.dispose();
      },
    ),
    // Sends a batched samples event through channel plumbing to ensure marshaling
    // and decoding remain cheap.
    BenchmarkDefinition(
      name: 'buffer/channel_samples_event',
      body: (_) async {
        final ReceivePort receiver = ReceivePort();
        final SendPort sender = receiver.sendPort;
        final Future<BufferSamplesEvent> received = receiver.first.then((
          dynamic event,
        ) {
          return event as BufferSamplesEvent;
        });
        sender.send(samplesEvent);
        final BufferSamplesEvent event = await received;
        blackHole(event.sampleCount);
        receiver.close();
      },
    ),
  ];
}

class _DatasetBufferProvider extends BufferDataProvider {
  _DatasetBufferProvider(this._samples);

  final List<BufferSample> _samples;

  @override
  Future<List<BufferSample>> fetchRange({
    required BufferSymbol symbol,
    required int startMicros,
    required int endMicros,
    required BufferInterval interval,
    required BufferEndpoint endpoint,
  }) async {
    final List<BufferSample> results = <BufferSample>[];
    for (final BufferSample sample in _samples) {
      if (sample.epochMicros >= startMicros && sample.epochMicros < endMicros) {
        results.add(sample);
      }
    }
    return results;
  }
}

class _WindowToken {
  const _WindowToken(this.startMicros, this.endMicros);

  final int startMicros;
  final int endMicros;

  @override
  bool operator ==(Object other) {
    return other is _WindowToken &&
        other.startMicros == startMicros &&
        other.endMicros == endMicros;
  }

  @override
  int get hashCode => Object.hash(startMicros, endMicros);
}

class _BufferWorkerHarness {
  _BufferWorkerHarness._({
    required SendPort commandPort,
    required RawReceivePort eventPort,
    required Map<_WindowToken, ListQueue<Completer<BufferSamplesEvent>>>
    pending,
    required Completer<void> termination,
    required int generation,
  }) : _commandPort = commandPort,
       _eventPort = eventPort,
       _pending = pending,
       _termination = termination,
       _generation = generation;

  final SendPort _commandPort;
  final RawReceivePort _eventPort;
  final Map<_WindowToken, ListQueue<Completer<BufferSamplesEvent>>> _pending;
  final Completer<void> _termination;
  int _generation;
  bool _isDisposed = false;

  int get generation => _generation;

  static Future<_BufferWorkerHarness> start({
    required BufferDataProvider provider,
    required BufferConfig config,
    required BufferPolicy policy,
  }) async {
    final Map<_WindowToken, ListQueue<Completer<BufferSamplesEvent>>> pending =
        <_WindowToken, ListQueue<Completer<BufferSamplesEvent>>>{};
    final Completer<BufferReadyEvent> readyCompleter =
        Completer<BufferReadyEvent>();
    final Completer<void> termination = Completer<void>();
    late RawReceivePort eventPort;
    eventPort = RawReceivePort((Object? message) {
      if (message is! BufferEvent) {
        return;
      }
      switch (message) {
        case BufferReadyEvent ready:
          if (!readyCompleter.isCompleted) {
            readyCompleter.complete(ready);
          }
          break;
        case BufferSamplesEvent event:
          final _WindowToken token = _WindowToken(
            event.window.startMicros,
            event.window.endMicros,
          );
          final ListQueue<Completer<BufferSamplesEvent>>? waiters =
              pending[token];
          if (waiters == null || waiters.isEmpty) {
            return;
          }
          final Completer<BufferSamplesEvent> completer = waiters.removeFirst();
          if (waiters.isEmpty) {
            pending.remove(token);
          }
          if (!completer.isCompleted) {
            completer.complete(event);
          }
          break;
        case BufferTerminatedEvent _:
          if (!termination.isCompleted) {
            termination.complete();
          }
          break;
        default:
          break;
      }
    });

    bufferWorkerMain(
      BufferWorkerBootstrap(eventPort: eventPort.sendPort, provider: provider),
    );

    final BufferReadyEvent ready = await readyCompleter.future;

    final _BufferWorkerHarness harness = _BufferWorkerHarness._(
      commandPort: ready.commandPort,
      eventPort: eventPort,
      pending: pending,
      termination: termination,
      generation: 1,
    );

    harness._commandPort.send(
      BufferSetConfigCommand(
        config: config,
        policy: policy,
        generation: harness._generation,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    return harness;
  }

  Future<BufferSampleSeries> requestRange(BufferRange window) async {
    final _WindowToken token = _WindowToken(
      window.startMicros,
      window.endMicros,
    );
    final Completer<BufferSamplesEvent> completer =
        Completer<BufferSamplesEvent>();
    final ListQueue<Completer<BufferSamplesEvent>> waiters = _pending
        .putIfAbsent(token, () {
          return ListQueue<Completer<BufferSamplesEvent>>();
        });
    waiters.addLast(completer);
    _commandPort.send(BufferSendRangeCommand(window: window));
    final BufferSamplesEvent event = await completer.future;
    return event.series;
  }

  Future<void> setPolicy(BufferPolicy policy) async {
    _generation += 1;
    _commandPort.send(
      BufferSetPolicyCommand(policy: policy, generation: _generation),
    );
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _commandPort.send(BufferDisposeCommand(generation: _generation));
    await _termination.future;
    for (final ListQueue<Completer<BufferSamplesEvent>> waiters
        in _pending.values) {
      while (waiters.isNotEmpty) {
        final Completer<BufferSamplesEvent> completer = waiters.removeFirst();
        if (!completer.isCompleted) {
          completer.completeError(StateError('Worker disposed'));
        }
      }
    }
    _pending.clear();
    _eventPort.close();
  }
}
