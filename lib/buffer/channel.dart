import 'dart:isolate';

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

abstract class BufferEvent {}

class BufferReadyEvent extends BufferEvent {
  BufferReadyEvent({required this.commandPort});

  final BufferCommandPort commandPort;
}

class BufferSamplesEvent extends BufferEvent {
  BufferSamplesEvent({
    required this.window,
    required List<BufferSample> samples,
  }) : samples = List<BufferSample>.unmodifiable(samples);

  final BufferRange window;
  final List<BufferSample> samples;
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
