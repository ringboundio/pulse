import 'package:pulse/buffer/channel.dart';

class BufferSampleStore {
  BufferSampleStore() : _samples = <BufferSample>[];

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
    for (int index = startIndex; index < _samples.length; index += 1) {
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
