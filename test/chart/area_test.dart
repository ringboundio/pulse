import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:pulse/chart/area.dart';
import 'package:pulse/chart/foundation.dart';
import 'package:pulse/chart/node.dart';
import 'package:pulse/chart/style.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const ChartStyleKey areaStyleKey = ChartStyleKey('test.area');
  const ChartTransform kTransform = ChartTransform(
    scaleX: 10.0,
    translateX: 0.0,
    scaleY: 50.0,
    translateY: 0.0,
    height: 200.0,
  );

  final ChartStyleSheet sheet = ChartStyleSheet(0, <ChartStyleEntry>[
    ChartStyleEntry(
      areaStyleKey,
      ChartPaintStyle(
        strokeColor: const Color(0xFF000000),
        strokeWidth: 1.5,
        strokeCap: StrokeCap.round,
        strokeJoin: StrokeJoin.round,
        dashPattern: Float64List(0),
        fillColor: const Color(0x33000000),
      ),
    ),
  ]);

  ChartRenderContext buildContext(PictureRecorder recorder) {
    return ChartRenderContext(
      canvas: Canvas(recorder),
      size: const Size(200, 200),
      transform: kTransform,
      styleSheet: sheet,
      paintCache: ChartPaintCache(),
      devicePixelRatio: 2.0,
      scratchSpace: ChartScratchSpace(),
    );
  }

  group('Chart area layer', () {
    // Ensures the fill path snaps to the baseline and caches per transform.
    test('fill path closes against the baseline and is cached', () {
      final ChartPolylineGeometry geometry =
          ChartPolylineGeometry.fromPoints(<ChartPoint>[
            const ChartPoint(0.0, 1.0),
            const ChartPoint(1.0, 2.0),
            const ChartPoint(2.0, 1.0),
          ]);
      final ChartAreaNode node = ChartAreaNode(
        const ChartNodeKey('area.node'),
        areaStyleKey,
        geometry,
        0.0,
      );
      final ChartAreaLayer layer = ChartAreaLayer(
        const ChartLayerKey('area.layer'),
        <ChartAreaNode>[node],
      );

      final Path first = node.fillPathForTransform(kTransform);
      expect(first.getBounds().bottom, closeTo(200.0, 1e-6));
      expect(
        first.computeMetrics().every((PathMetric metric) => metric.isClosed),
        isTrue,
      );

      final Path second = node.fillPathForTransform(kTransform);
      expect(identical(first, second), isTrue);

      final PictureRecorder recorder = PictureRecorder();
      final ChartRenderContext context = buildContext(recorder);
      layer.paint(context);
      recorder.endRecording().dispose();
    });
  });
}
