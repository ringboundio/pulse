import 'dart:isolate';
import 'dart:typed_data';

typedef BufferCommandPort = SendPort;
typedef BufferEventPort = SendPort;

enum BufferLogLevel { debug, info, warning, error }

class BufferSymbol {
  const BufferSymbol(this.value);

  final String value;
}

class BufferInterval {
  const BufferInterval(this.microseconds);

  final int microseconds;
}

class BufferEndpoint {
  const BufferEndpoint(this.value);

  final Uri value;
}

class BufferConfig {
  const BufferConfig({
    required this.symbol,
    required this.interval,
    required this.endpoint,
  });

  final BufferSymbol symbol;
  final BufferInterval interval;
  final BufferEndpoint endpoint;
}

class BufferPolicy {
  const BufferPolicy({
    required this.prefetchBackMicros,
    required this.prefetchForwardMicros,
  }) : assert(prefetchBackMicros >= 0),
       assert(prefetchForwardMicros >= 0);

  final int prefetchBackMicros;
  final int prefetchForwardMicros;
}

class BufferRange {
  const BufferRange({required this.startMicros, required this.endMicros})
    : assert(endMicros > startMicros);

  final int startMicros;
  final int endMicros;

  BufferRange expand(BufferPolicy policy) {
    return BufferRange(
      startMicros: startMicros - policy.prefetchBackMicros,
      endMicros: endMicros + policy.prefetchForwardMicros,
    );
  }
}

class BufferSample {
  const BufferSample({
    required this.epochMicros,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  final int epochMicros;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
}

class BufferSampleCodec {
  const BufferSampleCodec._();

  static const int bytesPerSample = 48;
  static const Endian _endian = Endian.little;
  static const Endian endian = _endian;

  static const int epochOffset = 0;
  static const int openOffset = 8;
  static const int highOffset = 16;
  static const int lowOffset = 24;
  static const int closeOffset = 32;
  static const int volumeOffset = 40;

  static void writeSample(ByteData data, int index, BufferSample sample) {
    final int offset = index * bytesPerSample;
    data.setInt64(offset, sample.epochMicros, _endian);
    data.setFloat64(offset + 8, sample.open, _endian);
    data.setFloat64(offset + 16, sample.high, _endian);
    data.setFloat64(offset + 24, sample.low, _endian);
    data.setFloat64(offset + 32, sample.close, _endian);
    data.setFloat64(offset + 40, sample.volume, _endian);
  }

  static BufferSample readSample(ByteData data, int index) {
    final int offset = index * bytesPerSample;
    return BufferSample(
      epochMicros: data.getInt64(offset, _endian),
      open: data.getFloat64(offset + 8, _endian),
      high: data.getFloat64(offset + 16, _endian),
      low: data.getFloat64(offset + 24, _endian),
      close: data.getFloat64(offset + 32, _endian),
      volume: data.getFloat64(offset + 40, _endian),
    );
  }
}

abstract class BufferSampleSeries {
  const BufferSampleSeries();

  static const BufferSampleSeries empty = _EmptyBufferSampleSeries.instance;

  int get length;

  bool get isEmpty => length == 0;

  int epochMicrosAt(int index);

  double openAt(int index);

  double highAt(int index);

  double lowAt(int index);

  double closeAt(int index);

  double volumeAt(int index);

  BufferSample materializeAt(int index) {
    return BufferSample(
      epochMicros: epochMicrosAt(index),
      open: openAt(index),
      high: highAt(index),
      low: lowAt(index),
      close: closeAt(index),
      volume: volumeAt(index),
    );
  }

  List<BufferSample> toList({bool growable = false}) {
    final List<BufferSample> result = List<BufferSample>.generate(
      length,
      materializeAt,
      growable: growable,
    );
    return result;
  }
}

class _EmptyBufferSampleSeries extends BufferSampleSeries {
  const _EmptyBufferSampleSeries();

  static const _EmptyBufferSampleSeries instance = _EmptyBufferSampleSeries();

  @override
  int get length => 0;

  @override
  int epochMicrosAt(int index) =>
      throw RangeError.index(index, this, 'index', null, length);

  @override
  double openAt(int index) =>
      throw RangeError.index(index, this, 'index', null, length);

  @override
  double highAt(int index) =>
      throw RangeError.index(index, this, 'index', null, length);

  @override
  double lowAt(int index) =>
      throw RangeError.index(index, this, 'index', null, length);

  @override
  double closeAt(int index) =>
      throw RangeError.index(index, this, 'index', null, length);

  @override
  double volumeAt(int index) =>
      throw RangeError.index(index, this, 'index', null, length);

  @override
  List<BufferSample> toList({bool growable = false}) =>
      growable ? <BufferSample>[] : const <BufferSample>[];
}

class _ListBufferSampleSeries extends BufferSampleSeries {
  const _ListBufferSampleSeries(this._samples);

  final List<BufferSample> _samples;

  @override
  int get length => _samples.length;

  @override
  int epochMicrosAt(int index) => _samples[index].epochMicros;

  @override
  double openAt(int index) => _samples[index].open;

  @override
  double highAt(int index) => _samples[index].high;

  @override
  double lowAt(int index) => _samples[index].low;

  @override
  double closeAt(int index) => _samples[index].close;

  @override
  double volumeAt(int index) => _samples[index].volume;

  @override
  BufferSample materializeAt(int index) => _samples[index];

  @override
  List<BufferSample> toList({bool growable = false}) => growable
      ? List<BufferSample>.of(_samples, growable: true)
      : List<BufferSample>.unmodifiable(_samples);
}

class _EncodedBufferSampleSeries extends BufferSampleSeries {
  const _EncodedBufferSampleSeries(this._data, this._count);

  final ByteData _data;
  final int _count;

  @override
  int get length => _count;

  int _offset(int index) => index * BufferSampleCodec.bytesPerSample;

  @override
  int epochMicrosAt(int index) {
    final int offset = _offset(index);
    return _data.getInt64(offset, BufferSampleCodec._endian);
  }

  @override
  double openAt(int index) {
    final int offset = _offset(index) + 8;
    return _data.getFloat64(offset, BufferSampleCodec._endian);
  }

  @override
  double highAt(int index) {
    final int offset = _offset(index) + 16;
    return _data.getFloat64(offset, BufferSampleCodec._endian);
  }

  @override
  double lowAt(int index) {
    final int offset = _offset(index) + 24;
    return _data.getFloat64(offset, BufferSampleCodec._endian);
  }

  @override
  double closeAt(int index) {
    final int offset = _offset(index) + 32;
    return _data.getFloat64(offset, BufferSampleCodec._endian);
  }

  @override
  double volumeAt(int index) {
    final int offset = _offset(index) + 40;
    return _data.getFloat64(offset, BufferSampleCodec._endian);
  }
}

abstract class BufferEvent {}

class BufferReadyEvent extends BufferEvent {
  BufferReadyEvent({required this.commandPort});

  final BufferCommandPort commandPort;
}

class BufferSamplesEvent extends BufferEvent {
  BufferSamplesEvent({
    required this.window,
    required List<BufferSample> samples,
  }) : _samples = List<BufferSample>.unmodifiable(samples),
       _payload = null,
       sampleCount = samples.length,
       _byteData = null,
       _series = null;

  BufferSamplesEvent.encoded({
    required this.window,
    required TransferableTypedData payload,
    required this.sampleCount,
  }) : _samples = null,
       _payload = payload,
       _byteData = null,
       _series = null;

  BufferSamplesEvent.empty({required this.window})
    : _samples = const <BufferSample>[],
      _payload = null,
      sampleCount = 0,
      _byteData = null,
      _series = _EmptyBufferSampleSeries.instance;

  final BufferRange window;
  final List<BufferSample>? _samples;
  TransferableTypedData? _payload;
  final int sampleCount;
  ByteData? _byteData;
  BufferSampleSeries? _series;

  BufferSampleSeries get series {
    final BufferSampleSeries? cached = _series;
    if (cached != null) {
      return cached;
    }
    final List<BufferSample>? direct = _samples;
    if (direct != null) {
      if (direct.isEmpty) {
        return _series = _EmptyBufferSampleSeries.instance;
      }
      return _series = _ListBufferSampleSeries(direct);
    }
    if (sampleCount == 0) {
      return _series = _EmptyBufferSampleSeries.instance;
    }
    final ByteData? data = _ensureMaterializedData();
    if (data == null) {
      return _series = _EmptyBufferSampleSeries.instance;
    }
    return _series = _EncodedBufferSampleSeries(data, sampleCount);
  }

  ByteData? _ensureMaterializedData() {
    final ByteData? cached = _byteData;
    if (cached != null) {
      return cached;
    }
    final TransferableTypedData? payload = _payload;
    if (payload == null) {
      return null;
    }
    final ByteBuffer buffer = payload.materialize();
    final ByteData data = buffer.asByteData();
    _byteData = data;
    _payload = null;
    return data;
  }
}

class BufferLogEvent extends BufferEvent {
  BufferLogEvent({required this.level, required this.message});

  final BufferLogLevel level;
  final String message;
}

class BufferTerminatedEvent extends BufferEvent {
  BufferTerminatedEvent({required this.generation});

  final int generation;
}

abstract class BufferCommand {}

class BufferSetConfigCommand extends BufferCommand {
  BufferSetConfigCommand({
    required this.config,
    required this.policy,
    required this.generation,
  });

  final BufferConfig config;
  final BufferPolicy policy;
  final int generation;
}

class BufferSetPolicyCommand extends BufferCommand {
  BufferSetPolicyCommand({required this.policy, required this.generation});

  final BufferPolicy policy;
  final int generation;
}

class BufferSendRangeCommand extends BufferCommand {
  BufferSendRangeCommand({required this.window});

  final BufferRange window;
}

class BufferDisposeCommand extends BufferCommand {
  BufferDisposeCommand({required this.generation});

  final int generation;
}

abstract class BufferDataProvider {
  const BufferDataProvider();

  Future<List<BufferSample>> fetchRange({
    required BufferSymbol symbol,
    required int startMicros,
    required int endMicros,
    required BufferInterval interval,
    required BufferEndpoint endpoint,
  });
}
