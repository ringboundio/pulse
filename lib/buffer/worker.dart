import 'dart:async';
import 'dart:isolate';

import 'package:pulse/buffer/channel.dart';
import 'package:pulse/buffer/sample_store.dart';

class BufferWorkerBootstrap {
  const BufferWorkerBootstrap({
    required this.eventPort,
    required this.provider,
  });

  final BufferEventPort eventPort;
  final BufferDataProvider provider;
}

void bufferWorkerMain(BufferWorkerBootstrap bootstrap) {
  final _BufferWorker worker = _BufferWorker(
    eventPort: bootstrap.eventPort,
    provider: bootstrap.provider,
  );
  worker.run();
}

class _BufferWorker {
  _BufferWorker({
    required BufferEventPort eventPort,
    required BufferDataProvider provider,
  }) : _eventPort = eventPort,
       _provider = provider,
       _samples = BufferSampleStore(),
       _policy = const BufferPolicy(
         prefetchBackMicros: 0,
         prefetchForwardMicros: 0,
       ),
       _configState = _ConfigState(),
       _lastRequest = _RangeSlot(
         const BufferRange(startMicros: 0, endMicros: 1),
       ),
       _generation = 0,
       _isDisposed = false,
       _coreInFlight = false,
       _haloInFlight = false;

  final BufferEventPort _eventPort;
  final BufferDataProvider _provider;
  final BufferSampleStore _samples;
  final _ConfigState _configState;
  final _RangeSlot _lastRequest;
  RawReceivePort? _commandReceivePort;

  BufferPolicy _policy;
  // Tracks the active configuration so background fetches can drop results
  // that completed after a newer config was installed.
  int _generation;
  bool _isDisposed;
  bool _coreInFlight;
  bool _haloInFlight;

  void run() {
    final RawReceivePort commandReceive = RawReceivePort(_handleCommand);
    _commandReceivePort = commandReceive;
    _eventPort.send(BufferReadyEvent(commandPort: commandReceive.sendPort));
  }

  void _handleCommand(Object? payload) {
    if (payload is BufferCommand) {
      _handlePayload(payload);
    }
  }

  void _handlePayload(BufferCommand payload) {
    if (_isDisposed) return;

    switch (payload) {
      case BufferDisposeCommand command:
        _handleDispose(command);
        return;
      case BufferSetConfigCommand command:
        _handleSetConfig(command);
        return;
      case BufferSetPolicyCommand command:
        _handleSetPolicy(command);
        return;
      case BufferSendRangeCommand command:
        _handleSendRange(command);
        return;
      default:
        return;
    }
  }

  void _handleSetConfig(BufferSetConfigCommand command) {
    _generation = command.generation;
    _policy = command.policy;
    _configState.assign(command.config);
    _samples.clear();
    _lastRequest.clear();
    _coreInFlight = false;
    _haloInFlight = false;
  }

  void _handleSetPolicy(BufferSetPolicyCommand command) {
    if (command.generation != _generation) {
      return;
    }
    _policy = command.policy;
    _trimToRetention();
  }

  void _handleSendRange(BufferSendRangeCommand command) {
    if (_coreInFlight) {
      return;
    }
    final BufferConfig config = _configState.require();
    final BufferRange window = command.window;
    _lastRequest.assign(window);

    if (_samples.covers(window)) {
      _trimToRetention();
      _emitWindow(window);
      _scheduleHalo(window, config);
      return;
    }

    _coreInFlight = true;
    // Capture the active configuration revision to spot stale completions.
    final int requestGeneration = _generation;
    unawaited(_fetchCoreRange(window, config, requestGeneration));
  }

  void _scheduleHalo(BufferRange window, BufferConfig config) {
    if (_haloInFlight) {
      return;
    }
    final BufferRange halo = window.expand(_policy);
    if (_samples.covers(halo)) {
      return;
    }
    _haloInFlight = true;
    final int requestGeneration = _generation;
    unawaited(_fetchHaloRange(halo, config, requestGeneration));
  }

  void _handleDispose(BufferDisposeCommand command) {
    _isDisposed = true;
    _commandReceivePort?.close();
    _commandReceivePort = null;
    _eventPort.send(BufferTerminatedEvent(generation: command.generation));
  }

  void _trimToRetention() {
    if (!_lastRequest.hasValue) {
      return;
    }
    final BufferRange retention = _lastRequest.value().expand(_policy);
    _samples.trim(retention.startMicros, retention.endMicros);
  }

  void _emitWindow(BufferRange window) {
    final BufferSampleWindowEncoding? encoding = _samples.encodeWindow(window);
    if (encoding == null) {
      _eventPort.send(BufferSamplesEvent.empty(window: window));
      return;
    }
    _eventPort.send(
      BufferSamplesEvent.encoded(
        window: window,
        payload: encoding.payload,
        sampleCount: encoding.count,
      ),
    );
  }

  Future<void> _fetchCoreRange(
    BufferRange window,
    BufferConfig config,
    int requestGeneration,
  ) async {
    try {
      final List<BufferSample> samples = await _provider.fetchRange(
        symbol: config.symbol,
        startMicros: window.startMicros,
        endMicros: window.endMicros,
        interval: config.interval,
        endpoint: config.endpoint,
      );
      if (_isDisposed || requestGeneration != _generation) {
        return;
      }
      _samples.merge(samples);
      _trimToRetention();
      _emitWindow(window);
      _scheduleHalo(window, config);
    } finally {
      _coreInFlight = false;
    }
  }

  Future<void> _fetchHaloRange(
    BufferRange halo,
    BufferConfig config,
    int requestGeneration,
  ) async {
    try {
      final List<BufferSample> samples = await _provider.fetchRange(
        symbol: config.symbol,
        startMicros: halo.startMicros,
        endMicros: halo.endMicros,
        interval: config.interval,
        endpoint: config.endpoint,
      );
      if (_isDisposed || requestGeneration != _generation) {
        return;
      }
      _samples.merge(samples);
      _trimToRetention();
    } finally {
      _haloInFlight = false;
    }
  }
}

class _ConfigState {
  _ConfigState();

  late BufferConfig _config;

  void assign(BufferConfig config) => _config = config;

  BufferConfig require() => _config;
}

class _RangeSlot {
  _RangeSlot(BufferRange seed) : _hasValue = false, _value = seed;

  bool _hasValue;
  BufferRange _value;

  bool get hasValue {
    return _hasValue;
  }

  void assign(BufferRange range) {
    _value = range;
    _hasValue = true;
  }

  void clear() {
    _hasValue = false;
  }

  BufferRange value() {
    return _value;
  }
}
