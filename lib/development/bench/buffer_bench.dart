import 'dart:async';
import 'dart:isolate';

import 'package:pulse/buffer/channel.dart';
import 'package:pulse/buffer/sample_store.dart';
import 'package:pulse/buffer/worker.dart';
import 'package:pulse/development/bench/benchmark.dart';
import 'package:pulse/development/bench/dataset.dart';

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
        final List<BufferSample> window = extractStore.extractWindow(
          queryRange,
        );
        blackHole(window.length);
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
        final List<BufferSample> fetched = await harness.requestRange(
          queryRange,
        );
        blackHole(fetched.length);
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
        blackHole(event.samples.length);
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

class _BufferWorkerHarness {
  _BufferWorkerHarness._({
    required SendPort commandPort,
    required StreamController<BufferEvent> controller,
    required StreamSubscription<dynamic> subscription,
    required ReceivePort eventPort,
    required int generation,
  }) : _commandPort = commandPort,
       _controller = controller,
       _subscription = subscription,
       _eventPort = eventPort,
       _generation = generation;

  final SendPort _commandPort;
  final StreamController<BufferEvent> _controller;
  final StreamSubscription<dynamic> _subscription;
  final ReceivePort _eventPort;
  int _generation;
  bool _isDisposed = false;

  int get generation => _generation;

  static Future<_BufferWorkerHarness> start({
    required BufferDataProvider provider,
    required BufferConfig config,
    required BufferPolicy policy,
  }) async {
    final ReceivePort eventPort = ReceivePort();
    final StreamController<BufferEvent> controller =
        StreamController<BufferEvent>.broadcast();
    final StreamSubscription<dynamic> subscription = eventPort.listen((
      dynamic message,
    ) {
      if (message is BufferEvent) {
        controller.add(message);
      }
    });

    bufferWorkerMain(
      BufferWorkerBootstrap(eventPort: eventPort.sendPort, provider: provider),
    );

    final BufferReadyEvent ready = await controller.stream
        .where((BufferEvent event) => event is BufferReadyEvent)
        .cast<BufferReadyEvent>()
        .first;

    final _BufferWorkerHarness harness = _BufferWorkerHarness._(
      commandPort: ready.commandPort,
      controller: controller,
      subscription: subscription,
      eventPort: eventPort,
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

  Future<List<BufferSample>> requestRange(BufferRange window) async {
    final Future<BufferSamplesEvent> response = _controller.stream
        .where((BufferEvent event) => event is BufferSamplesEvent)
        .cast<BufferSamplesEvent>()
        .firstWhere(
          (BufferSamplesEvent event) =>
              event.window.startMicros == window.startMicros &&
              event.window.endMicros == window.endMicros,
        );
    _commandPort.send(BufferSendRangeCommand(window: window));
    final BufferSamplesEvent event = await response;
    return event.samples;
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
    await _controller.stream
        .where((BufferEvent event) => event is BufferTerminatedEvent)
        .cast<BufferTerminatedEvent>()
        .first;
    await _subscription.cancel();
    await _controller.close();
    _eventPort.close();
  }
}
