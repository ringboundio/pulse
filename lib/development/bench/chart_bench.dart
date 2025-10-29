import 'dart:ui';

import 'package:pulse/chart/area.dart';
import 'package:pulse/chart/bar.dart';
import 'package:pulse/chart/candle.dart';
import 'package:pulse/chart/foundation.dart';
import 'package:pulse/chart/line.dart';
import 'package:pulse/chart/node.dart';
import 'package:pulse/chart/style.dart';
import 'package:pulse/development/bench/benchmark.dart';
import 'package:pulse/development/bench/dataset.dart';

List<BenchmarkDefinition> buildChartBenchmarks() {
  final ChartBenchmarkDataset data = chartBenchmarkDataset;
  final List<ChartPoint> points = data.polylinePoints;
  final ChartPolylineGeometry polylineGeometry = data.createPolylineGeometry();
  final ChartScratchSpace scratch = ChartScratchSpace();
  final ChartTransform transform = const ChartTransform(
    scaleX: 2.0,
    translateX: 0.0,
    scaleY: 180.0,
    translateY: 0.0,
    height: 360.0,
  );
  ChartStyleSheet sheet = data.createStyleSheet();
  final List<ChartStyleEntry> styleEntries = data.styleEntries;
  final ChartPaintCache cacheHit = ChartPaintCache();
  final ChartStyleKey hitKey = styleEntries.first.key;
  cacheHit.resolve(sheet, hitKey);

  int missRevision = sheet.revision + 1;
  int missKeyIndex = 0;
  final List<ChartStyleKey> missKeys = styleEntries
      .map((ChartStyleEntry entry) => entry.key)
      .toList();

  final ChartAreaNode areaNode = ChartAreaNode(
    const ChartNodeKey('area.node'),
    styleEntries[0].key,
    polylineGeometry,
    -0.25,
  );
  final ChartAreaLayer areaLayer = ChartAreaLayer(
    const ChartLayerKey('area.layer'),
    <ChartAreaNode>[areaNode],
  );

  final ChartLineLayer lineLayer =
      ChartLineLayer(const ChartLayerKey('line.layer'), <ChartLineNode>[
        ChartLineNode(
          const ChartNodeKey('line.node'),
          styleEntries[1].key,
          polylineGeometry,
        ),
      ]);

  final ChartCandleGeometry candleGeometry = data.createCandleGeometry();
  final ChartCandleLayer candleLayer =
      ChartCandleLayer(const ChartLayerKey('candle.layer'), <ChartCandleNode>[
        ChartCandleNode(
          const ChartNodeKey('candle.node'),
          styleEntries[2].key,
          candleGeometry,
        ),
      ]);

  final ChartBarGeometry barGeometry = data.createBarGeometry();
  final ChartBarLayer barLayer = ChartBarLayer(
    const ChartLayerKey('bar.layer'),
    <ChartBarNode>[
      ChartBarNode(
        const ChartNodeKey('bar.node'),
        styleEntries[3].key,
        barGeometry,
      ),
    ],
  );

  final ChartPaintCache layerPaintCache = ChartPaintCache();
  final ChartPaintCache framePaintCache = ChartPaintCache();
  const Size canvasSize = Size(1024, 360);

  ChartRenderContext createContext(Canvas canvas, ChartPaintCache cache) {
    return ChartRenderContext(
      canvas: canvas,
      size: canvasSize,
      transform: transform,
      styleSheet: sheet,
      paintCache: cache,
      devicePixelRatio: 2.0,
      scratchSpace: scratch,
    );
  }

  return <BenchmarkDefinition>[
    // Builds polyline geometry from precomputed sample points to measure
    // geometry allocation overhead.
    BenchmarkDefinition(
      name: 'chart/polyline_from_points',
      body: (_) {
        final ChartPolylineGeometry created = ChartPolylineGeometry.fromPoints(
          points,
        );
        blackHole(created.positions.length);
      },
    ),
    // Writes polyline geometry into a reusable path to measure tessellation
    // and path metric cost.
    BenchmarkDefinition(
      name: 'chart/polyline_write_path',
      body: (_) {
        final Path path = polylineGeometry.pathForTransform(transform);
        blackHole(path.computeMetrics().length);
      },
    ),
    // Generates the fill path for an area layer to track polygon generation
    // work separate from painting.
    BenchmarkDefinition(
      name: 'chart/area_write_fill',
      body: (_) {
        final Path fill = areaNode.fillPathForTransform(transform);
        blackHole(fill.computeMetrics().length);
      },
    ),
    // Resolves styles from the paint cache with a hot key to ensure cache hits
    // stay cheap.
    BenchmarkDefinition(
      name: 'chart/paint_cache_hit',
      body: (_) {
        final ChartPaintBundle bundle = cacheHit.resolve(sheet, hitKey);
        blackHole(bundle.stroke);
      },
    ),
    // Forces paint cache misses by bumping revisions so we capture the penalty
    // of rebuilding bundled paints.
    BenchmarkDefinition(
      name: 'chart/paint_cache_miss',
      body: (int iteration) {
        missKeyIndex = (missKeyIndex + 1) % missKeys.length;
        sheet = ChartStyleSheet(missRevision, styleEntries);
        missRevision += 1;
        final ChartPaintCache cache = ChartPaintCache();
        final ChartPaintBundle bundle = cache.resolve(
          sheet,
          missKeys[missKeyIndex],
        );
        blackHole(bundle.fill);
      },
    ),
    // Renders a candle layer into an offscreen picture to benchmark a single
    // complex frame-oriented paint path.
    BenchmarkDefinition(
      name: 'chart/candle_layer_paint',
      tags: const <BenchmarkTag>['frame'],
      body: (_) {
        final PictureRecorder recorder = PictureRecorder();
        final Canvas canvas = Canvas(recorder);
        scratch.reset();
        final ChartRenderContext context = createContext(
          canvas,
          layerPaintCache,
        );
        candleLayer.paint(context);
        final Picture picture = recorder.endRecording();
        blackHole(picture.approximateBytesUsed);
        picture.dispose();
      },
    ),
    // Renders a bar layer into an offscreen picture to track the cost of
    // drawing our discrete column visuals.
    BenchmarkDefinition(
      name: 'chart/bar_layer_paint',
      tags: const <BenchmarkTag>['frame'],
      body: (_) {
        final PictureRecorder recorder = PictureRecorder();
        final Canvas canvas = Canvas(recorder);
        scratch.reset();
        final ChartRenderContext context = createContext(
          canvas,
          layerPaintCache,
        );
        barLayer.paint(context);
        final Picture picture = recorder.endRecording();
        blackHole(picture.approximateBytesUsed);
        picture.dispose();
      },
    ),
    // Paints the representative dashboard frame combining area, line, candle,
    // and bar layers to catch regressions across the full composition.
    BenchmarkDefinition(
      name: 'chart/frame_composite_paint',
      tags: const <BenchmarkTag>['frame'],
      body: (_) {
        final PictureRecorder recorder = PictureRecorder();
        final Canvas canvas = Canvas(recorder);
        final ChartRenderContext context = createContext(
          canvas,
          framePaintCache,
        );
        scratch.reset();
        areaLayer.paint(context);
        scratch.reset();
        lineLayer.paint(context);
        scratch.reset();
        candleLayer.paint(context);
        scratch.reset();
        barLayer.paint(context);
        final Picture picture = recorder.endRecording();
        blackHole(picture.approximateBytesUsed);
        picture.dispose();
      },
    ),
  ];
}
