import 'dart:async';
import 'dart:math';

import 'package:pulse/buffer/channel.dart';

class DevelopmentBufferDataProvider extends BufferDataProvider {
  const DevelopmentBufferDataProvider({
    this.networkLatency = const Duration(milliseconds: 120),
    this.driftPerMillionMicros = 0.0000025,
    this.volatility = 0.018,
    this.baseVolume = 18500.0,
  });

  final Duration networkLatency;
  final double driftPerMillionMicros;
  final double volatility;
  final double baseVolume;

  @override
  Future<List<BufferSample>> fetchRange({
    required BufferSymbol symbol,
    required int startMicros,
    required int endMicros,
    required BufferInterval interval,
    required BufferEndpoint endpoint,
  }) async {
    if (startMicros >= endMicros) {
      return <BufferSample>[];
    }

    if (interval.microseconds <= 0) {
      throw ArgumentError('Interval must be positive microseconds.');
    }

    if (networkLatency > Duration.zero) {
      await Future<void>.delayed(networkLatency);
    }

    final int stepMicros = interval.microseconds;
    final List<BufferSample> samples = <BufferSample>[];
    final int seed = _seedForSymbol(symbol.value, endpoint.value.toString());
    final Random random = Random(seed);

    double price = _initialPriceForSymbol(symbol.value);
    int epochMicros = startMicros;

    while (epochMicros < endMicros) {
      final double drift = driftPerMillionMicros * stepMicros / 1000000.0;
      final double seasonal = _seasonalAdjustment(epochMicros);
      final double shock = (random.nextDouble() * 2.0 - 1.0) * volatility;

      final double open = price;
      final double closeCandidate = open * (1.0 + drift + seasonal + shock);
      final double close = closeCandidate > 1.0 ? closeCandidate : 1.0;
      final double highBase = open > close ? open : close;
      final double lowBase = open < close ? open : close;

      final double high = highBase * (1.0 + random.nextDouble() * 0.0045);
      final double low = lowBase * (1.0 - random.nextDouble() * 0.0045);

      final double volume = _volumeForEpoch(
        random,
        baseVolume,
        epochMicros,
        symbol.value,
      );

      samples.add(
        BufferSample(
          epochMicros: epochMicros,
          open: open,
          high: high,
          low: low < 0.01 ? 0.01 : low,
          close: close,
          volume: volume,
        ),
      );

      price = close;
      epochMicros = epochMicros + stepMicros;
    }

    return samples;
  }
}

int _seedForSymbol(String symbol, String endpoint) {
  int hash = 17;
  for (int index = 0; index < symbol.length; index = index + 1) {
    hash = hash * 31 + symbol.codeUnitAt(index);
  }
  for (int index = 0; index < endpoint.length; index = index + 1) {
    hash = hash * 37 + endpoint.codeUnitAt(index);
  }
  if (hash < 0) {
    hash = hash * -1;
  }
  return hash;
}

double _initialPriceForSymbol(String symbol) {
  int sum = 0;
  for (int index = 0; index < symbol.length; index = index + 1) {
    sum = sum + symbol.codeUnitAt(index);
  }
  final int bounded = 60 + (sum % 140);
  return bounded.toDouble();
}

double _seasonalAdjustment(int epochMicros) {
  const int microsPerDay = 86400000000;
  const int microsPerWeek = microsPerDay * 5;
  final double dayPhase =
      (epochMicros % microsPerDay).toDouble() / microsPerDay;
  final double weekPhase =
      (epochMicros % microsPerWeek).toDouble() / microsPerWeek;
  final double intradayWave = sin(dayPhase * 2.0 * pi) * 0.0025;
  final double weeklyWave = sin(weekPhase * 2.0 * pi) * 0.0035;
  return intradayWave + weeklyWave;
}

double _volumeForEpoch(
  Random random,
  double baseVolume,
  int epochMicros,
  String symbol,
) {
  const int microsPerDay = 86400000000;
  final double phase = (epochMicros % microsPerDay).toDouble() / microsPerDay;
  final double openingRamp = 1.0 + 0.35 * exp(-phase * 6.0);
  final double closingRamp = 1.0 + 0.25 * exp(-(1.0 - phase) * 6.0);
  final double noise = 0.65 + random.nextDouble() * 0.9;
  final double symbolBias = 0.75 + (symbol.length.toDouble() / 20.0);
  return baseVolume * openingRamp * closingRamp * noise * symbolBias;
}
