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
    // Confirms BufferSamplesEvent exposes an immutable samples list.
    test('samples list is unmodifiable', () {
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

      expect(
        () => event.samples.add(
          const BufferSample(
            epochMicros: 2,
            open: 2,
            high: 2,
            low: 2,
            close: 2,
            volume: 2,
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
