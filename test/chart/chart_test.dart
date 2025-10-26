import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:pulse/chart/chart.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Ensures controller notifies listeners when styles change.
  test('ChartController notifies listeners and increments revision', () {
    final ChartStyleKey styleKey = ChartStyleKey('line-primary');
    final ChartPolylineGeometry geometry = ChartPolylineGeometry.fromPoints(
      <ChartPoint>[ChartPoint(0.0, 0.0), ChartPoint(10.0, 5.0)],
    );
    final ChartLineNode node = ChartLineNode(
      ChartNodeKey('node-0'),
      styleKey,
      geometry,
    );
    final ChartLineLayer layer = ChartLineLayer(
      ChartLayerKey('layer-line'),
      <ChartLineNode>[node],
    );
    final ChartScene scene = ChartScene(
      ChartSpace(ChartDoubleRange(0.0, 10.0), ChartDoubleRange(0.0, 10.0), 2.0),
      <ChartLayer>[layer],
    );
    final ChartPaintStyle initialStyle = ChartPaintStyle(
      const Color(0xFF3567F6),
      2.0,
      StrokeCap.round,
      StrokeJoin.round,
      Float64List(0),
      const Color(0x00000000),
    );
    final ChartSceneGraph graph = ChartSceneGraph(
      scene,
      ChartStyleSheet(0, <ChartStyleEntry>[
        ChartStyleEntry(styleKey, initialStyle),
      ]),
    );

    final ChartController controller = ChartController(graph);
    int notifications = 0;
    controller.addListener(() {
      notifications += 1;
    });

    controller.overrideStyle(
      styleKey,
      ChartPaintStyle(
        const Color(0xFFF6455A),
        3.0,
        StrokeCap.round,
        StrokeJoin.round,
        Float64List(0),
        const Color(0x00000000),
      ),
    );

    expect(controller.revision, 1);
    expect(notifications, 1);
  });

  // Verifies paint cache invalidates bundles only on sheet revision changes.
  test('ChartPaintCache reuses bundles until revision changes', () {
    final ChartStyleKey styleKey = ChartStyleKey('grid');
    final ChartPaintStyle style = ChartPaintStyle(
      const Color(0xFF99A2B0),
      1.0,
      StrokeCap.square,
      StrokeJoin.miter,
      Float64List(0),
      const Color(0x00000000),
    );
    final ChartStyleSheet sheet = ChartStyleSheet(5, <ChartStyleEntry>[
      ChartStyleEntry(styleKey, style),
    ]);

    final ChartPaintCache cache = ChartPaintCache();
    final ChartPaintBundle first = cache.resolve(sheet, styleKey);
    final ChartPaintBundle second = cache.resolve(sheet, styleKey);
    expect(identical(first, second), isTrue);

    final ChartStyleSheet updatedSheet = sheet.override(
      styleKey,
      ChartPaintStyle(
        const Color(0xFF111111),
        1.5,
        StrokeCap.square,
        StrokeJoin.miter,
        Float64List(0),
        const Color(0x00000000),
      ),
    );
    final ChartPaintBundle third = cache.resolve(updatedSheet, styleKey);
    expect(identical(first, third), isFalse);
  });

  // Confirms renderer can draw a simple line chart into a picture recorder.
  test('ChartRenderer renders simple line scene to picture', () {
    final ChartStyleKey styleKey = ChartStyleKey('line');
    final ChartPolylineGeometry geometry = ChartPolylineGeometry.fromPoints(
      <ChartPoint>[
        ChartPoint(0.0, 0.0),
        ChartPoint(5.0, 2.0),
        ChartPoint(10.0, 4.0),
      ],
    );
    final ChartLineNode node = ChartLineNode(
      ChartNodeKey('line-node'),
      styleKey,
      geometry,
    );
    final ChartScene scene = ChartScene(
      ChartSpace(ChartDoubleRange(0.0, 10.0), ChartDoubleRange(0.0, 5.0), 2.0),
      <ChartLayer>[
        ChartLineLayer(ChartLayerKey('line-layer'), <ChartLineNode>[node]),
      ],
    );
    final ChartPaintStyle style = ChartPaintStyle(
      const Color(0xFF00AACC),
      2.0,
      StrokeCap.round,
      StrokeJoin.round,
      Float64List(0),
      const Color(0x00000000),
    );
    final ChartSceneGraph graph = ChartSceneGraph(
      scene,
      ChartStyleSheet(0, <ChartStyleEntry>[ChartStyleEntry(styleKey, style)]),
    );

    final ChartRenderer renderer = ChartRenderer();
    final ChartPaintCache cache = ChartPaintCache();
    final ChartScratchSpace scratchSpace = ChartScratchSpace();

    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    renderer.render(
      canvas,
      const Size(200.0, 100.0),
      graph,
      cache,
      scratchSpace,
    );
    final Picture picture = recorder.endRecording();

    expect(picture, isNotNull);
    picture.dispose();
  });

  // Ensures area node produces a closed fill path for painting.
  test('ChartAreaNode fill path is closed', () {
    final Float32List coordinates = Float32List(6);
    coordinates[0] = 0.0;
    coordinates[1] = 1.0;
    coordinates[2] = 5.0;
    coordinates[3] = 3.0;
    coordinates[4] = 10.0;
    coordinates[5] = 2.0;
    final ChartPolylineGeometry upper = ChartPolylineGeometry(coordinates);
    final ChartAreaNode node = ChartAreaNode(
      ChartNodeKey('area'),
      ChartStyleKey('area-style'),
      upper,
      0.0,
    );
    final Path fill = Path();
    final ChartTransform transform = ChartTransform(1.0, 0.0, 1.0, 0.0, 100.0);
    node.writeFill(fill, transform);

    final PathMetrics metrics = fill.computeMetrics();
    int closedCount = 0;
    for (final PathMetric metric in metrics) {
      if (metric.isClosed) {
        closedCount += 1;
      }
    }
    expect(closedCount, greaterThan(0));
  });
}
