import 'dart:async';
import 'dart:isolate';

import 'package:pulse/buffer/channel.dart';

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
       _samples = _SampleStore(),
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
  final _SampleStore _samples;
  final _ConfigState _configState;
  final _RangeSlot _lastRequest;

  BufferPolicy _policy;
  // Tracks the active configuration so background fetches can drop results
  // that completed after a newer config was installed.
  int _generation;
  bool _isDisposed;
  bool _coreInFlight;
  bool _haloInFlight;

  void run() {
    final ReceivePort commandReceive = ReceivePort();
    _eventPort.send(BufferReadyEvent(commandPort: commandReceive.sendPort));
    commandReceive.listen((payload) {
      if (payload is BufferCommand) {
        _handlePayload(payload);
      }
    });
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
      final List<BufferSample> cached = _samples.extractWindow(window);
      _trimToRetention();
      _emitSamples(window, cached);
      _scheduleHalo(window, config);
      return;
    }

    _coreInFlight = true;
    // Capture the active configuration revision to spot stale completions.
    final int requestGeneration = _generation;
    Future<void>(() async {
      final List<BufferSample> samples = await _provider.fetchRange(
        symbol: config.symbol,
        startMicros: window.startMicros,
        endMicros: window.endMicros,
        interval: config.interval,
        endpoint: config.endpoint,
      );
      if (_isDisposed || requestGeneration != _generation) {
        _coreInFlight = false;
        return;
      }
      _samples.merge(samples);
      _trimToRetention();
      _coreInFlight = false;
      _emitSamples(window, _samples.extractWindow(window));
      _scheduleHalo(window, config);
    });
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
    Future<void>(() async {
      final List<BufferSample> samples = await _provider.fetchRange(
        symbol: config.symbol,
        startMicros: halo.startMicros,
        endMicros: halo.endMicros,
        interval: config.interval,
        endpoint: config.endpoint,
      );
      if (_isDisposed || requestGeneration != _generation) {
        _haloInFlight = false;
        return;
      }
      _samples.merge(samples);
      _trimToRetention();
      _haloInFlight = false;
    });
  }

  void _handleDispose(BufferDisposeCommand command) {
    _isDisposed = true;
    _eventPort.send(BufferTerminatedEvent(generation: command.generation));
  }

  void _trimToRetention() {
    if (!_lastRequest.hasValue) {
      return;
    }
    final BufferRange retention = _lastRequest.value().expand(_policy);
    _samples.trim(retention.startMicros, retention.endMicros);
  }

  void _emitSamples(BufferRange window, List<BufferSample> samples) {
    _eventPort.send(BufferSamplesEvent(window: window, samples: samples));
  }
}

class _SampleStore {
  _SampleStore() : _samples = <BufferSample>[];

  final List<BufferSample> _samples;

  void clear() {
    _samples.clear();
  }

  void merge(List<BufferSample> incoming) {
    for (final BufferSample sample in incoming) {
      _insert(sample);
    }
  }

  void _insert(BufferSample sample) {
    final int index = _lowerBound(sample.epochMicros);
    if (index < _samples.length &&
        _samples[index].epochMicros == sample.epochMicros) {
      _samples[index] = sample;
      return;
    }
    _samples.insert(index, sample);
  }

  int _lowerBound(int epochMicros) {
    int low = 0;
    int high = _samples.length;
    while (low < high) {
      final int mid = low + ((high - low) >> 1);
      final BufferSample candidate = _samples[mid];
      if (candidate.epochMicros < epochMicros) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  List<BufferSample> extractWindow(BufferRange window) {
    final int startIndex = _lowerBound(window.startMicros);
    final List<BufferSample> subset = <BufferSample>[];
    for (int index = startIndex; index < _samples.length; index = index + 1) {
      final BufferSample sample = _samples[index];
      if (sample.epochMicros >= window.endMicros) {
        break;
      }
      subset.add(sample);
    }
    return subset;
  }

  bool covers(BufferRange window) {
    if (_samples.isEmpty) {
      return false;
    }
    final int firstEpoch = _samples.first.epochMicros;
    final int lastEpoch = _samples.last.epochMicros;
    if (window.startMicros < firstEpoch) {
      return false;
    }
    if (window.endMicros - 1 > lastEpoch) {
      return false;
    }
    return true;
  }

  void trim(int startMicros, int endMicros) {
    final int frontIndex = _lowerBound(startMicros);
    if (frontIndex > 0) {
      _samples.removeRange(0, frontIndex);
    }
    final int backIndex = _lowerBound(endMicros);
    if (backIndex < _samples.length) {
      _samples.removeRange(backIndex, _samples.length);
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
