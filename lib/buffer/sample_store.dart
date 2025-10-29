import 'dart:isolate';
import 'dart:typed_data';

import 'package:pulse/buffer/channel.dart';

class BufferSampleWindowEncoding {
  const BufferSampleWindowEncoding({
    required this.payload,
    required this.count,
  });

  final TransferableTypedData payload;
  final int count;
}

class BufferSampleStore {
  BufferSampleStore({int initialCapacity = 0})
    : _samples = List<BufferSample>.empty(growable: true);

  static const int _bytesPerSample = BufferSampleCodec.bytesPerSample;
  static const Endian _endian = BufferSampleCodec.endian;

  List<BufferSample> _samples;
  Int64List _epochsCache = Int64List(0);
  Float64List _openCache = Float64List(0);
  Float64List _highCache = Float64List(0);
  Float64List _lowCache = Float64List(0);
  Float64List _closeCache = Float64List(0);
  Float64List _volumeCache = Float64List(0);
  Uint8List _packedCache = Uint8List(0);
  bool _columnCachesValid = false;
  bool _packedCacheValid = false;

  bool get isEmpty => _samples.isEmpty;

  int get length => _samples.length;

  void clear() {
    if (_samples.isEmpty) {
      return;
    }
    _samples.clear();
    _invalidateCaches();
  }

  void merge(List<BufferSample> incoming) {
    if (incoming.isEmpty) {
      return;
    }

    final List<BufferSample> sorted = _ensureSorted(incoming);
    if (_samples.isEmpty) {
      _samples = List<BufferSample>.of(sorted, growable: true);
      _invalidateCaches();
      return;
    }

    if (sorted.length == 1) {
      _insert(sorted.first);
      return;
    }

    final int firstIncomingEpoch = sorted.first.epochMicros;
    final int lastExistingEpoch = _samples.last.epochMicros;
    if (firstIncomingEpoch >= lastExistingEpoch) {
      _appendSorted(sorted);
      return;
    }

    _mergeWith(sorted);
  }

  BufferSampleSeries extractSeries(BufferRange window) {
    final int startIndex = _lowerBound(window.startMicros);
    if (startIndex >= _samples.length) {
      return BufferSampleSeries.empty;
    }
    final int endIndex = _lowerBound(window.endMicros);
    final int count = endIndex - startIndex;
    if (count <= 0) {
      return BufferSampleSeries.empty;
    }
    _ensureColumnCaches();
    return _ColumnBufferSampleSeries(
      epochs: _epochsCache,
      open: _openCache,
      high: _highCache,
      low: _lowCache,
      close: _closeCache,
      volume: _volumeCache,
      start: startIndex,
      count: count,
    );
  }

  List<BufferSample> extractWindow(BufferRange window) {
    final int startIndex = _lowerBound(window.startMicros);
    if (startIndex >= _samples.length) {
      return const <BufferSample>[];
    }
    final int endIndex = _lowerBound(window.endMicros);
    final int count = endIndex - startIndex;
    if (count <= 0) {
      return const <BufferSample>[];
    }
    return List<BufferSample>.generate(
      count,
      (int index) => _samples[startIndex + index],
      growable: false,
    );
  }

  BufferSampleWindowEncoding? encodeWindow(BufferRange window) {
    final int startIndex = _lowerBound(window.startMicros);
    if (startIndex >= _samples.length) {
      return null;
    }
    final int endIndex = _lowerBound(window.endMicros);
    final int count = endIndex - startIndex;
    if (count <= 0) {
      return null;
    }
    _ensurePackedCache();
    final int byteLength = count * _bytesPerSample;
    final int startByte = startIndex * _bytesPerSample;
    final Uint8List bytes = Uint8List.sublistView(
      _packedCache,
      startByte,
      startByte + byteLength,
    );
    return BufferSampleWindowEncoding(
      payload: TransferableTypedData.fromList(<Uint8List>[bytes]),
      count: count,
    );
  }

  bool covers(BufferRange window) {
    if (_samples.isEmpty) {
      return false;
    }
    final int firstEpoch = _samples.first.epochMicros;
    if (window.startMicros < firstEpoch) {
      return false;
    }
    final int lastEpoch = _samples.last.epochMicros;
    if (window.endMicros - 1 > lastEpoch) {
      return false;
    }
    return true;
  }

  void trim(int startMicros, int endMicros) {
    if (_samples.isEmpty) {
      return;
    }
    final int frontIndex = _lowerBound(startMicros);
    if (frontIndex > 0) {
      _samples.removeRange(0, frontIndex);
    }
    if (_samples.isEmpty) {
      _invalidateCaches();
      return;
    }
    final int backIndex = _lowerBound(endMicros);
    if (backIndex < _samples.length) {
      _samples.removeRange(backIndex, _samples.length);
    }
    _invalidateCaches();
  }

  List<BufferSample> toList() {
    if (_samples.isEmpty) {
      return const <BufferSample>[];
    }
    return List<BufferSample>.of(_samples, growable: false);
  }

  void _insert(BufferSample sample) {
    final int index = _lowerBound(sample.epochMicros);
    if (index < _samples.length &&
        _samples[index].epochMicros == sample.epochMicros) {
      _samples[index] = sample;
    } else {
      _samples.insert(index, sample);
    }
    _invalidateCaches();
  }

  void _appendSorted(List<BufferSample> samples) {
    int sourceIndex = 0;
    if (_samples.isNotEmpty &&
        samples.first.epochMicros == _samples.last.epochMicros) {
      _samples[_samples.length - 1] = samples.first;
      sourceIndex = 1;
    }
    if (sourceIndex < samples.length) {
      _samples.addAll(samples.getRange(sourceIndex, samples.length));
    }
    _invalidateCaches();
  }

  void _mergeWith(List<BufferSample> incoming) {
    final List<BufferSample> merged = <BufferSample>[];

    int existingIndex = 0;
    int incomingIndex = 0;

    while (existingIndex < _samples.length && incomingIndex < incoming.length) {
      final BufferSample existingSample = _samples[existingIndex];
      final BufferSample incomingSample = incoming[incomingIndex];
      if (existingSample.epochMicros <= incomingSample.epochMicros) {
        if (existingSample.epochMicros == incomingSample.epochMicros) {
          merged.add(incomingSample);
          existingIndex += 1;
          incomingIndex += 1;
        } else {
          merged.add(existingSample);
          existingIndex += 1;
        }
      } else {
        merged.add(incomingSample);
        incomingIndex += 1;
      }
    }

    if (existingIndex < _samples.length) {
      merged.addAll(_samples.getRange(existingIndex, _samples.length));
    }
    if (incomingIndex < incoming.length) {
      merged.addAll(incoming.getRange(incomingIndex, incoming.length));
    }

    _samples = merged;
    _invalidateCaches();
  }

  int _lowerBound(int epochMicros) {
    int low = 0;
    int high = _samples.length;
    while (low < high) {
      final int mid = low + ((high - low) >> 1);
      if (_samples[mid].epochMicros < epochMicros) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  void _invalidateCaches() {
    _columnCachesValid = false;
    _packedCacheValid = false;
  }

  void _ensureColumnCaches() {
    if (_columnCachesValid) {
      return;
    }
    final int count = _samples.length;
    if (count == 0) {
      _epochsCache = Int64List(0);
      _openCache = Float64List(0);
      _highCache = Float64List(0);
      _lowCache = Float64List(0);
      _closeCache = Float64List(0);
      _volumeCache = Float64List(0);
      _columnCachesValid = true;
      return;
    }
    final Int64List epochs = Int64List(count);
    final Float64List open = Float64List(count);
    final Float64List high = Float64List(count);
    final Float64List low = Float64List(count);
    final Float64List close = Float64List(count);
    final Float64List volume = Float64List(count);
    for (int index = 0; index < count; index += 1) {
      final BufferSample sample = _samples[index];
      epochs[index] = sample.epochMicros;
      open[index] = sample.open;
      high[index] = sample.high;
      low[index] = sample.low;
      close[index] = sample.close;
      volume[index] = sample.volume;
    }
    _epochsCache = epochs;
    _openCache = open;
    _highCache = high;
    _lowCache = low;
    _closeCache = close;
    _volumeCache = volume;
    _columnCachesValid = true;
  }

  void _ensurePackedCache() {
    if (_packedCacheValid) {
      return;
    }
    final int count = _samples.length;
    if (count == 0) {
      _packedCache = Uint8List(0);
      _packedCacheValid = true;
      return;
    }
    final Uint8List bytes = Uint8List(count * _bytesPerSample);
    final ByteData data = ByteData.view(bytes.buffer);
    for (int index = 0; index < count; index += 1) {
      final BufferSample sample = _samples[index];
      _writePackedTo(
        data,
        index,
        sample.epochMicros,
        sample.open,
        sample.high,
        sample.low,
        sample.close,
        sample.volume,
      );
    }
    _packedCache = bytes;
    _packedCacheValid = true;
  }

  List<BufferSample> _ensureSorted(List<BufferSample> samples) {
    if (samples.length < 2) {
      return samples;
    }
    for (int index = 1; index < samples.length; index += 1) {
      if (samples[index - 1].epochMicros > samples[index].epochMicros) {
        final List<BufferSample> sorted = List<BufferSample>.of(samples);
        sorted.sort(
          (BufferSample a, BufferSample b) =>
              a.epochMicros.compareTo(b.epochMicros),
        );
        return sorted;
      }
    }
    return samples;
  }

  static void _writePackedTo(
    ByteData data,
    int index,
    int epoch,
    double open,
    double high,
    double low,
    double close,
    double volume,
  ) {
    final int offset = index * _bytesPerSample;
    data.setInt64(offset + BufferSampleCodec.epochOffset, epoch, _endian);
    data.setFloat64(offset + BufferSampleCodec.openOffset, open, _endian);
    data.setFloat64(offset + BufferSampleCodec.highOffset, high, _endian);
    data.setFloat64(offset + BufferSampleCodec.lowOffset, low, _endian);
    data.setFloat64(offset + BufferSampleCodec.closeOffset, close, _endian);
    data.setFloat64(offset + BufferSampleCodec.volumeOffset, volume, _endian);
  }
}

class _ColumnBufferSampleSeries extends BufferSampleSeries {
  const _ColumnBufferSampleSeries({
    required Int64List epochs,
    required Float64List open,
    required Float64List high,
    required Float64List low,
    required Float64List close,
    required Float64List volume,
    required int start,
    required int count,
  }) : _epochs = epochs,
       _open = open,
       _high = high,
       _low = low,
       _close = close,
       _volume = volume,
       _start = start,
       _count = count;

  final Int64List _epochs;
  final Float64List _open;
  final Float64List _high;
  final Float64List _low;
  final Float64List _close;
  final Float64List _volume;
  final int _start;
  final int _count;

  @override
  int get length => _count;

  int _index(int offset) => _start + offset;

  @override
  int epochMicrosAt(int index) => _epochs[_index(index)];

  @override
  double openAt(int index) => _open[_index(index)];

  @override
  double highAt(int index) => _high[_index(index)];

  @override
  double lowAt(int index) => _low[_index(index)];

  @override
  double closeAt(int index) => _close[_index(index)];

  @override
  double volumeAt(int index) => _volume[_index(index)];

  @override
  BufferSample materializeAt(int index) {
    final int resolved = _index(index);
    return BufferSample(
      epochMicros: _epochs[resolved],
      open: _open[resolved],
      high: _high[resolved],
      low: _low[resolved],
      close: _close[resolved],
      volume: _volume[resolved],
    );
  }

  @override
  List<BufferSample> toList({bool growable = false}) {
    return List<BufferSample>.generate(
      _count,
      (int index) => materializeAt(index),
      growable: growable,
    );
  }
}
