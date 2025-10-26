import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/buffer/channel.dart';
import 'package:pulse/buffer/client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Validates the isolate-backed client fetches data and surfaces samples.
  test('fetches range data and emits samples', () async {
    final provider = _RecordingBufferDataProvider([
      const BufferSample(
        epochMicros: 8,
        open: 1,
        high: 2,
        low: 0.5,
        close: 1.5,
        volume: 10,
      ),
      const BufferSample(
        epochMicros: 12,
        open: 1.5,
        high: 2.5,
        low: 1,
        close: 2,
        volume: 12,
      ),
    ]);

    final client = await BufferClient.spawn(provider: provider);
    addTearDown(client.dispose);

    const symbol = BufferSymbol('ABC');
    const interval = BufferInterval(1);
    final endpoint = BufferEndpoint(Uri.parse('https://example.com/api'));
    const window = BufferRange(startMicros: 0, endMicros: 16);

    final received = <BufferSamplesEvent>[];
    final samplesSub = client.samples.listen(received.add);
    addTearDown(samplesSub.cancel);

    client.setConfig(symbol: symbol, interval: interval, endpoint: endpoint);

    client.sendRange(
      startMicros: window.startMicros,
      endMicros: window.endMicros,
    );

    await _waitUntil(() => received.isNotEmpty);

    final event = received.last;
    expect(event.window.startMicros, window.startMicros);
    expect(event.window.endMicros, window.endMicros);
    expect(event.samples, orderedEquals(provider.samples));
  });
}

Future<void> _waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 3),
  Duration interval = const Duration(milliseconds: 10),
}) async {
  final stopwatch = Stopwatch()..start();
  while (!condition()) {
    if (stopwatch.elapsed > timeout) {
      fail('Timed out waiting for condition');
    }
    await Future<void>.delayed(interval);
  }
}

class _RecordingBufferDataProvider extends BufferDataProvider {
  _RecordingBufferDataProvider(this.samples);

  final List<BufferSample> samples;

  @override
  Future<List<BufferSample>> fetchRange({
    required BufferSymbol symbol,
    required int startMicros,
    required int endMicros,
    required BufferInterval interval,
    required BufferEndpoint endpoint,
  }) async {
    return samples;
  }
}
