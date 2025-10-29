import 'package:flutter_test/flutter_test.dart';

import 'package:pulse/buffer/channel.dart';

void main() {
  group('BufferRange', () {
    // Validates expand adjusts start and end by the policy offsets.
    test('expand respects policy', () {
      const range = BufferRange(startMicros: 10, endMicros: 20);
      const policy = BufferPolicy(
        prefetchBackMicros: 5,
        prefetchForwardMicros: 3,
      );

      final expanded = range.expand(policy);

      expect(expanded.startMicros, 5);
      expect(expanded.endMicros, 23);
    });
  });

  group('BufferSamplesEvent', () {
    // Confirms BufferSamplesEvent exposes series that mirror the source data.
    test('series reflects provided samples', () {
      const window = BufferRange(startMicros: 0, endMicros: 10);
      final event = BufferSamplesEvent(
        window: window,
        samples: [
          const BufferSample(
            epochMicros: 1,
            open: 1,
            high: 1,
            low: 1,
            close: 1,
            volume: 1,
          ),
        ],
      );

      final BufferSampleSeries series = event.series;
      expect(identical(series, event.series), isTrue);
      expect(series.length, 1);
      final BufferSample sample = series.materializeAt(0);
      expect(sample.epochMicros, 1);
      expect(sample.open, 1);
      expect(sample.high, 1);
      expect(sample.low, 1);
      expect(sample.close, 1);
      expect(sample.volume, 1);

      final List<BufferSample> list = series.toList();
      expect(list, hasLength(1));
      expect(
        () => list[0] = const BufferSample(
          epochMicros: 2,
          open: 2,
          high: 2,
          low: 2,
          close: 2,
          volume: 2,
        ),
        throwsUnsupportedError,
      );
      final BufferSample preserved = series.materializeAt(0);
      expect(preserved.epochMicros, 1);
      expect(preserved.open, 1);
      expect(preserved.close, 1);
    });
  });
}
