import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:pulse/buffer/channel.dart';
import 'package:pulse/chart/area.dart';
import 'package:pulse/chart/candle.dart';
import 'package:pulse/chart/controller.dart';
import 'package:pulse/chart/data.dart';
import 'package:pulse/chart/foundation.dart';
import 'package:pulse/chart/grid.dart';
import 'package:pulse/chart/line.dart';
import 'package:pulse/chart/node.dart';
import 'package:pulse/chart/style.dart';

class DevelopmentChartStyles {
  DevelopmentChartStyles()
    : gridDomain = ChartStyleKey('development.grid.domain'),
      gridMeasure = ChartStyleKey('development.grid.measure'),
      candleBull = ChartStyleKey('development.candle.bull'),
      candleBear = ChartStyleKey('development.candle.bear'),
      closeLine = ChartStyleKey('development.close.line'),
      volumeArea = ChartStyleKey('development.volume.area'),
      volumeBar = ChartStyleKey('development.volume.bar');

  final ChartStyleKey gridDomain;
  final ChartStyleKey gridMeasure;
  final ChartStyleKey candleBull;
  final ChartStyleKey candleBear;
  final ChartStyleKey closeLine;
  final ChartStyleKey volumeArea;
  final ChartStyleKey volumeBar;

  ChartStyleSheet sheet() {
    final Float64List solidPattern = Float64List(0);
    final Float64List dashedPattern = Float64List(2);
    dashedPattern[0] = 4.0;
    dashedPattern[1] = 4.0;

    final List<ChartStyleEntry> entries = <ChartStyleEntry>[
      ChartStyleEntry(
        gridDomain,
        ChartPaintStyle(
          strokeColor: const Color(0xFF2E3238),
          strokeWidth: 1.0,
          strokeCap: StrokeCap.butt,
          strokeJoin: StrokeJoin.miter,
          dashPattern: dashedPattern,
          fillColor: const Color(0x002E3238),
        ),
      ),
      ChartStyleEntry(
        gridMeasure,
        ChartPaintStyle(
          strokeColor: const Color(0xFF24272D),
          strokeWidth: 1.0,
          strokeCap: StrokeCap.butt,
          strokeJoin: StrokeJoin.miter,
          dashPattern: dashedPattern,
          fillColor: const Color(0x0024272D),
        ),
      ),
      ChartStyleEntry(
        candleBull,
        ChartPaintStyle(
          strokeColor: const Color(0xFF4CAF50),
          strokeWidth: 1.0,
          strokeCap: StrokeCap.butt,
          strokeJoin: StrokeJoin.miter,
          dashPattern: solidPattern,
          fillColor: const Color(0xBF4CAF50),
        ),
      ),
      ChartStyleEntry(
        candleBear,
        ChartPaintStyle(
          strokeColor: const Color(0xFFEF5350),
          strokeWidth: 1.0,
          strokeCap: StrokeCap.butt,
          strokeJoin: StrokeJoin.miter,
          dashPattern: solidPattern,
          fillColor: const Color(0xBFEF5350),
        ),
      ),
      ChartStyleEntry(
        closeLine,
        ChartPaintStyle(
          strokeColor: const Color(0xFF42A5F5),
          strokeWidth: 2.0,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
          dashPattern: solidPattern,
          fillColor: const Color(0x0042A5F5),
        ),
      ),
      ChartStyleEntry(
        volumeArea,
        ChartPaintStyle(
          strokeColor: const Color(0x3342A5F5),
          strokeWidth: 1.0,
          strokeCap: StrokeCap.butt,
          strokeJoin: StrokeJoin.miter,
          dashPattern: solidPattern,
          fillColor: const Color(0x3342A5F5),
        ),
      ),
      ChartStyleEntry(
        volumeBar,
        ChartPaintStyle(
          strokeColor: const Color(0xFF39424A),
          strokeWidth: 1.0,
          strokeCap: StrokeCap.butt,
          strokeJoin: StrokeJoin.miter,
          dashPattern: solidPattern,
          fillColor: const Color(0xFF39424A),
        ),
      ),
    ];

    return ChartStyleSheet(0, entries);
  }
}

class DevelopmentChartAssembler {
  DevelopmentChartAssembler({
    required ChartController controller,
    required DevelopmentChartStyles styles,
  }) : _controller = controller,
       _styles = styles,
       _styleSheet = styles.sheet(),
       _layerKeyGrid = ChartLayerKey('development.layer.grid'),
       _layerKeyCandles = ChartLayerKey('development.layer.candles'),
       _layerKeyLine = ChartLayerKey('development.layer.close.line'),
       _layerKeyVolume = ChartLayerKey('development.layer.volume'),
       _volumeNodeKey = ChartNodeKey('development.node.volume'),
       _closeNodeKey = ChartNodeKey('development.node.close.line'),
       _bullNodeKey = ChartNodeKey('development.node.candles.bull'),
       _bearNodeKey = ChartNodeKey('development.node.candles.bear');

  final ChartController _controller;
  final DevelopmentChartStyles _styles;
  final ChartStyleSheet _styleSheet;
  final ChartLayerKey _layerKeyGrid;
  final ChartLayerKey _layerKeyCandles;
  final ChartLayerKey _layerKeyLine;
  final ChartLayerKey _layerKeyVolume;
  final ChartNodeKey _volumeNodeKey;
  final ChartNodeKey _closeNodeKey;
  final ChartNodeKey _bullNodeKey;
  final ChartNodeKey _bearNodeKey;

  ChartSceneGraph bootstrapGraph() {
    final ChartSpace space = ChartSpace(
      ChartDoubleRange(0.0, 1.0),
      ChartDoubleRange(0.0, 1.0),
      1.0,
    );
    final ChartScene scene = ChartScene(space, <ChartLayer>[]);
    return ChartSceneGraph(scene, _styleSheet);
  }

  ChartStyleSheet styleSheet() {
    return _styleSheet;
  }

  void updateGraph({
    required List<BufferSample> samples,
    required int viewportStartMicros,
    required int viewportEndMicros,
    required double devicePixelRatio,
  }) {
    final ChartSceneGraph graph = _buildGraph(
      samples: samples,
      viewportStartMicros: viewportStartMicros,
      viewportEndMicros: viewportEndMicros,
      devicePixelRatio: devicePixelRatio,
    );
    _controller.setGraph(graph);
  }

  ChartSceneGraph _buildGraph({
    required List<BufferSample> samples,
    required int viewportStartMicros,
    required int viewportEndMicros,
    required double devicePixelRatio,
  }) {
    final double windowSpan = (viewportEndMicros - viewportStartMicros)
        .toDouble();
    final double domainMin = viewportStartMicros.toDouble();
    final double domainMax = windowSpan > 0.0
        ? viewportEndMicros.toDouble()
        : domainMin + 1.0;

    double measureMin = double.infinity;
    double measureMax = double.negativeInfinity;
    double maxVolume = 0.0;
    for (int index = 0; index < samples.length; index += 1) {
      final BufferSample sample = samples[index];
      if (sample.low < measureMin) {
        measureMin = sample.low;
      }
      if (sample.high > measureMax) {
        measureMax = sample.high;
      }
      if (sample.volume > maxVolume) {
        maxVolume = sample.volume;
      }
    }

    if (!measureMin.isFinite ||
        !measureMax.isFinite ||
        measureMax <= measureMin) {
      measureMin = 0.0;
      measureMax = 1.0;
    } else {
      final double padding = (measureMax - measureMin) * 0.08;
      measureMin = measureMin - padding;
      measureMax = measureMax + padding;
    }

    if (maxVolume <= 0.0) {
      maxVolume = 1.0;
    }

    final ChartSpace space = ChartSpace(
      ChartDoubleRange(domainMin, domainMax),
      ChartDoubleRange(measureMin, measureMax),
      devicePixelRatio,
    );

    final ChartSceneBuilder builder = ChartSceneBuilder(space);
    builder.addLayer(_buildGridLayer(space));
    builder.addLayer(
      _buildVolumeLayer(
        samples: samples,
        maxVolume: maxVolume,
        baseline: space.measure.min,
        measureSpan: space.measure.span,
      ),
    );
    builder.addLayer(_buildCandleLayer(samples));
    builder.addLayer(_buildCloseLineLayer(samples));

    final ChartScene scene = builder.build();
    return ChartSceneGraph(scene, _styleSheet);
  }

  ChartLayer _buildGridLayer(ChartSpace space) {
    const int divisions = 6;
    final Float32List domainLines = Float32List(divisions);
    final Float32List measureLines = Float32List(divisions);

    final double domainSpan = space.domain.span;
    final double measureSpan = space.measure.span;

    for (int index = 0; index < divisions; index += 1) {
      final double position = index / (divisions - 1);
      domainLines[index] = space.domain.min + domainSpan * position;
      measureLines[index] = space.measure.min + measureSpan * position;
    }

    return ChartGridLayer(
      _layerKeyGrid,
      domainLines: domainLines,
      measureLines: measureLines,
      domainStyleKey: _styles.gridDomain,
      measureStyleKey: _styles.gridMeasure,
    );
  }

  ChartLayer _buildVolumeLayer({
    required List<BufferSample> samples,
    required double maxVolume,
    required double baseline,
    required double measureSpan,
  }) {
    if (samples.isEmpty) {
      final ChartPolylineGeometry emptyGeometry = ChartPolylineGeometry(
        Float32List(0),
      );
      final ChartAreaNode node = ChartAreaNode(
        _volumeNodeKey,
        _styles.volumeArea,
        emptyGeometry,
        baseline,
      );
      return ChartAreaLayer(_layerKeyVolume, <ChartAreaNode>[node]);
    }

    final List<ChartPoint> points = <ChartPoint>[];
    final double amplitude = measureSpan > 0.0 ? measureSpan * 0.12 : 1.0;
    for (int index = 0; index < samples.length; index += 1) {
      final BufferSample sample = samples[index];
      final double normalized = sample.volume / maxVolume;
      final double measureValue = baseline + normalized * amplitude;
      points.add(ChartPoint(sample.epochMicros.toDouble(), measureValue));
    }

    final ChartPolylineGeometry geometry = ChartPolylineGeometry.fromPoints(
      points,
    );
    final ChartAreaNode node = ChartAreaNode(
      _volumeNodeKey,
      _styles.volumeArea,
      geometry,
      baseline,
    );
    return ChartAreaLayer(_layerKeyVolume, <ChartAreaNode>[node]);
  }

  ChartLayer _buildCandleLayer(List<BufferSample> samples) {
    final double halfWidth = _determineHalfWidth(samples);
    final List<double> bullValues = <double>[];
    final List<double> bearValues = <double>[];
    for (int index = 0; index < samples.length; index += 1) {
      final BufferSample sample = samples[index];
      final List<double> target = sample.close >= sample.open
          ? bullValues
          : bearValues;
      target.add(sample.epochMicros.toDouble());
      target.add(sample.open);
      target.add(sample.high);
      target.add(sample.low);
      target.add(sample.close);
      target.add(halfWidth);
    }

    final List<ChartCandleNode> nodes = <ChartCandleNode>[];
    if (bullValues.isNotEmpty) {
      final Float32List data = Float32List(bullValues.length);
      for (int index = 0; index < bullValues.length; index += 1) {
        data[index] = bullValues[index];
      }
      final ChartCandleNode node = ChartCandleNode(
        _bullNodeKey,
        _styles.candleBull,
        ChartCandleGeometry(data),
      );
      nodes.add(node);
    }

    if (bearValues.isNotEmpty) {
      final Float32List data = Float32List(bearValues.length);
      for (int index = 0; index < bearValues.length; index += 1) {
        data[index] = bearValues[index];
      }
      final ChartCandleNode node = ChartCandleNode(
        _bearNodeKey,
        _styles.candleBear,
        ChartCandleGeometry(data),
      );
      nodes.add(node);
    }

    return ChartCandleLayer(_layerKeyCandles, nodes);
  }

  ChartLayer _buildCloseLineLayer(List<BufferSample> samples) {
    final List<ChartPoint> points = <ChartPoint>[];
    for (int index = 0; index < samples.length; index += 1) {
      final BufferSample sample = samples[index];
      points.add(ChartPoint(sample.epochMicros.toDouble(), sample.close));
    }
    final ChartPolylineGeometry geometry = ChartPolylineGeometry.fromPoints(
      points,
    );
    final ChartLineNode node = ChartLineNode(
      _closeNodeKey,
      _styles.closeLine,
      geometry,
    );
    return ChartLineLayer(_layerKeyLine, <ChartLineNode>[node]);
  }

  double _determineHalfWidth(List<BufferSample> samples) {
    if (samples.length < 2) {
      return 0.4;
    }
    double totalInterval = 0.0;
    for (int index = 1; index < samples.length; index += 1) {
      final double previous = samples[index - 1].epochMicros.toDouble();
      final double current = samples[index].epochMicros.toDouble();
      totalInterval += current - previous;
    }
    final double average = totalInterval / (samples.length - 1);
    return max(0.4, average * 0.45);
  }
}
