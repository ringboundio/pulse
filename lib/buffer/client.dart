import 'dart:async';
import 'dart:isolate';

import 'package:pulse/buffer/channel.dart';
import 'package:pulse/buffer/worker.dart';

abstract class BufferClient {
  Stream<BufferSamplesEvent> get samples;
  Stream<BufferLogEvent> get logs;

  void setConfig({
    required BufferSymbol symbol,
    required BufferInterval interval,
    required BufferEndpoint endpoint,
  });

  void setPolicy({
    required int prefetchBackMicros,
    required int prefetchForwardMicros,
  });

  void sendRange({required int startMicros, required int endMicros});

  void dispose();

  static Future<BufferClient> spawn({
    required BufferDataProvider provider,
  }) async {
    final client = _IsolateBufferClient(provider: provider);
    await client.launch();
    return client;
  }
}

class _IsolateBufferClient implements BufferClient {
  _IsolateBufferClient({required BufferDataProvider provider})
    : _provider = provider,
      _eventPort = ReceivePort(),
      _samples = StreamController<BufferSamplesEvent>.broadcast(sync: true),
      _logs = StreamController<BufferLogEvent>.broadcast(sync: true),
      _pendingCommands = <BufferCommand>[],
      _currentPolicy = const BufferPolicy(
        prefetchBackMicros: 0,
        prefetchForwardMicros: 0,
      ),
      _generation = 0;

  final BufferDataProvider _provider;
  final ReceivePort _eventPort;
  final StreamController<BufferSamplesEvent> _samples;
  final StreamController<BufferLogEvent> _logs;
  final List<BufferCommand> _pendingCommands;

  late final Future<Isolate> _isolateFuture;
  late BufferCommandPort _commandPort;
  BufferPolicy _currentPolicy;
  // Mirrors the worker's generation so we can invalidate any commands or
  // responses issued prior to the most recent setConfig call.
  int _generation;
  bool _hasCommandPort = false;
  bool _disposed = false;
  bool _shuttingDown = false;

  @override
  Stream<BufferSamplesEvent> get samples => _samples.stream;

  @override
  Stream<BufferLogEvent> get logs => _logs.stream;

  Future<void> launch() async {
    _eventPort.listen((payload) {
      if (payload is BufferEvent) _handleEvent(payload);
    });

    _isolateFuture = Isolate.spawn(
      bufferWorkerMain,
      BufferWorkerBootstrap(
        eventPort: _eventPort.sendPort,
        provider: _provider,
      ),
    );

    await _isolateFuture;
  }

  @override
  void setConfig({
    required BufferSymbol symbol,
    required BufferInterval interval,
    required BufferEndpoint endpoint,
  }) {
    if (_disposed || _shuttingDown) return;
    _generation += 1;
    final cmd = BufferSetConfigCommand(
      config: BufferConfig(
        symbol: symbol,
        interval: interval,
        endpoint: endpoint,
      ),
      policy: _currentPolicy,
      generation: _generation,
    );
    _enqueue(cmd);
  }

  @override
  void setPolicy({
    required int prefetchBackMicros,
    required int prefetchForwardMicros,
  }) {
    if (_disposed || _shuttingDown) return;
    _currentPolicy = BufferPolicy(
      prefetchBackMicros: prefetchBackMicros,
      prefetchForwardMicros: prefetchForwardMicros,
    );
    _enqueue(
      BufferSetPolicyCommand(policy: _currentPolicy, generation: _generation),
    );
  }

  @override
  void sendRange({required int startMicros, required int endMicros}) {
    if (_disposed || _shuttingDown) throw StateError('disposed');
    _enqueue(
      BufferSendRangeCommand(
        window: BufferRange(startMicros: startMicros, endMicros: endMicros),
      ),
    );
  }

  void _enqueue(BufferCommand command) {
    if (_disposed || _shuttingDown) return;
    if (!_hasCommandPort) {
      _pendingCommands.add(command);
      return;
    }
    _commandPort.send(command);
  }

  void _handleEvent(BufferEvent event) {
    if (_disposed || _shuttingDown) return;

    switch (event) {
      case BufferReadyEvent ready:
        _commandPort = ready.commandPort;
        _hasCommandPort = true;
        for (final command in _pendingCommands) {
          _commandPort.send(command);
        }
        _pendingCommands.clear();
        return;
      case BufferSamplesEvent samplesEvent:
        _samples.add(samplesEvent);
        return;
      case BufferLogEvent logEvent:
        _logs.add(logEvent);
        return;
      case BufferTerminatedEvent _:
        return;
      default:
        return;
    }
  }

  void _disposeStreams() {
    if (_disposed) return;
    _disposed = true;
    _samples.close();
    _logs.close();
    _eventPort.close();
  }

  @override
  void dispose() {
    if (_disposed || _shuttingDown) return;
    _shuttingDown = true;
    if (_hasCommandPort) {
      _commandPort.send(BufferDisposeCommand(generation: _generation));
    }
    _pendingCommands.clear();
    _isolateFuture.then((isolate) => isolate.kill(priority: Isolate.immediate));
    _disposeStreams();
  }
}
