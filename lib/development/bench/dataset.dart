import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/painting.dart';

import 'package:pulse/buffer/channel.dart';
import 'package:pulse/buffer/sample_store.dart';
import 'package:pulse/chart/node.dart';
import 'package:pulse/chart/style.dart';

final ChartBenchmarkDataset chartBenchmarkDataset = ChartBenchmarkDataset._();
final BufferBenchmarkDataset bufferBenchmarkDataset =
    BufferBenchmarkDataset._();

class ChartBenchmarkDataset {
  factory ChartBenchmarkDataset._() {
    final List<ChartPoint> points = _buildPolylinePoints();
    final Float32List polylineSource = _buildPolylineBuffer(points);
    final Float32List candleSource = _buildCandleBuffer();
    final Float32List barSource = _buildBarBuffer();
    final List<ChartStyleEntry> styles = _buildStyleEntries();
    return ChartBenchmarkDataset._internal(
      polylinePoints: List<ChartPoint>.unmodifiable(points),
      polylineSource: polylineSource,
      candleSource: candleSource,
      barSource: barSource,
      styleEntries: List<ChartStyleEntry>.unmodifiable(styles),
    );
  }

  ChartBenchmarkDataset._internal({
    required this.polylinePoints,
    required Float32List polylineSource,
    required Float32List candleSource,
    required Float32List barSource,
    required this.styleEntries,
  }) : _polylineSource = polylineSource,
       _candleSource = candleSource,
       _barSource = barSource,
       defaultStyleSheet = ChartStyleSheet(0, styleEntries);

  final List<ChartPoint> polylinePoints;
  final Float32List _polylineSource;
  final Float32List _candleSource;
  final Float32List _barSource;
  final List<ChartStyleEntry> styleEntries;
  final ChartStyleSheet defaultStyleSheet;

  ChartPolylineGeometry createPolylineGeometry() {
    return ChartPolylineGeometry(_polylineSource);
  }

  ChartPolylineGeometry createBaselineGeometry(double offset) {
    final Float32List source = Float32List(_polylineSource.length);
    for (int i = 0; i < _polylineSource.length; i += 2) {
      source[i] = _polylineSource[i];
      source[i + 1] = offset;
    }
    return ChartPolylineGeometry(source);
  }

  ChartCandleGeometry createCandleGeometry() {
    return ChartCandleGeometry(_candleSource);
  }

  ChartBarGeometry createBarGeometry() {
    return ChartBarGeometry(_barSource);
  }

  ChartStyleSheet createStyleSheet({int revision = 0}) {
    return ChartStyleSheet(revision, styleEntries);
  }

  static List<ChartPoint> _buildPolylinePoints() {
    const int count = 1024;
    final List<ChartPoint> points = <ChartPoint>[];
    for (int i = 0; i < count; i += 1) {
      final double domain = i.toDouble();
      final double measure = math.sin(domain / 24.0);
      points.add(ChartPoint(domain, measure));
    }
    return points;
  }

  static Float32List _buildPolylineBuffer(List<ChartPoint> points) {
    final Float32List buffer = Float32List(points.length * 2);
    int index = 0;
    for (final ChartPoint point in points) {
      buffer[index] = point.domain;
      buffer[index + 1] = point.measure;
      index += 2;
    }
    return buffer;
  }

  static Float32List _buildCandleBuffer() {
    const int count = 512;
    final Float32List buffer = Float32List(count * 6);
    int offset = 0;
    for (int i = 0; i < count; i += 1) {
      final double domain = i.toDouble();
      final double base = math.sin(i / 18.0);
      final double trend = math.sin(i / 64.0) * 0.2;
      final double body = math.sin(i / 11.0) * 0.08;
      final double open = base + trend + body;
      final double close = base + trend - body;
      final double wickOffsetHigh = 0.35 + math.sin(i / 7.0) * 0.05;
      final double wickOffsetLow = 0.33 + math.cos(i / 5.0) * 0.05;
      final double high = math.max(open, close) + wickOffsetHigh;
      final double low = math.min(open, close) - wickOffsetLow;
      const double halfWidth = 0.35;
      buffer[offset + 0] = domain;
      buffer[offset + 1] = open;
      buffer[offset + 2] = high;
      buffer[offset + 3] = low;
      buffer[offset + 4] = close;
      buffer[offset + 5] = halfWidth;
      offset += 6;
    }
    return buffer;
  }

  static Float32List _buildBarBuffer() {
    const int count = 512;
    final Float32List buffer = Float32List(count * 4);
    int offset = 0;
    for (int i = 0; i < count; i += 1) {
      final double domain = i.toDouble();
      final double intensity = 0.6 + math.sin(i / 9.0) * 0.25;
      final double low = 0.0;
      final double high = low + intensity.abs();
      const double halfWidth = 0.45;
      buffer[offset + 0] = domain;
      buffer[offset + 1] = low;
      buffer[offset + 2] = high;
      buffer[offset + 3] = halfWidth;
      offset += 4;
    }
    return buffer;
  }

  static List<ChartStyleEntry> _buildStyleEntries() {
    const int count = 64;
    final List<ChartStyleEntry> entries = <ChartStyleEntry>[];
    for (int index = 0; index < count; index += 1) {
      final double hue = (index / count) * 360.0;
      final Color strokeColor = HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor();
      final Color fillColor = strokeColor.withValues(alpha: 0.2);
      final Float64List dashPattern = index.isEven
          ? Float64List(0)
          : Float64List.fromList(<double>[4.0 + index, 3.0 + (index / 2.0)]);
      entries.add(
        ChartStyleEntry(
          ChartStyleKey('style.$index'),
          ChartPaintStyle(
            strokeColor: strokeColor,
            strokeWidth: 1.0 + (index % 4) * 0.5,
            strokeCap: StrokeCap.round,
            strokeJoin: StrokeJoin.round,
            dashPattern: dashPattern,
            fillColor: fillColor,
          ),
        ),
      );
    }
    return entries;
  }
}

class BufferBenchmarkDataset {
  factory BufferBenchmarkDataset._() {
    final List<BufferSample> samples = _buildSamples();
    return BufferBenchmarkDataset._internal(
      samples: List<BufferSample>.unmodifiable(samples),
      policy: const BufferPolicy(
        prefetchBackMicros: 1200000,
        prefetchForwardMicros: 900000,
      ),
      queryRange: _buildQueryRange(samples),
      trimRange: _buildTrimRange(samples),
      config: BufferConfig(
        symbol: const BufferSymbol('TEST'),
        interval: const BufferInterval(60000),
        endpoint: BufferEndpoint(Uri.parse('https://example.com/buffer')),
      ),
    );
  }

  BufferBenchmarkDataset._internal({
    required this.samples,
    required this.policy,
    required this.queryRange,
    required this.trimRange,
    required this.config,
  });

  final List<BufferSample> samples;
  final BufferPolicy policy;
  final BufferRange queryRange;
  final BufferRange trimRange;
  final BufferConfig config;

  BufferSampleStore createSampleStore() {
    final BufferSampleStore store = BufferSampleStore();
    store.merge(samples);
    return store;
  }

  static List<BufferSample> _buildSamples() {
    const int count = 4096;
    const int baseEpoch = 1000000;
    const int interval = 60000;
    final List<BufferSample> samples = <BufferSample>[];
    for (int index = 0; index < count; index += 1) {
      final int epoch = baseEpoch + (index * interval);
      final double base = 200.0 + 40.0 * math.sin(index / 18.0);
      final double volatility = 1.2 + math.sin(index / 6.0) * 0.4;
      final double open = base - 0.6 + math.sin(index / 9.0) * 0.45;
      final double close = base + 0.6 + math.cos(index / 11.0) * 0.45;
      final double high = math.max(open, close) + volatility;
      final double low = math.min(open, close) - volatility;
      samples.add(
        BufferSample(
          epochMicros: epoch,
          open: open,
          high: high,
          low: low,
          close: close,
          volume: 1e6 + (index * 1e3),
        ),
      );
    }
    return samples;
  }

  static BufferRange _buildQueryRange(List<BufferSample> samples) {
    return BufferRange(
      startMicros: samples[1024].epochMicros,
      endMicros: samples[2048].epochMicros,
    );
  }

  static BufferRange _buildTrimRange(List<BufferSample> samples) {
    return BufferRange(
      startMicros: samples[512].epochMicros,
      endMicros: samples[3072].epochMicros,
    );
  }
}
