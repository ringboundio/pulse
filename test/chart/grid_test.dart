import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:pulse/chart/foundation.dart';
import 'package:pulse/chart/grid.dart';
import 'package:pulse/chart/style.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const ChartStyleKey gridDomainStyleKey = ChartStyleKey('test.grid.domain');
  const ChartStyleKey gridMeasureStyleKey = ChartStyleKey('test.grid.measure');
  const ChartTransform kTransform = ChartTransform(
    scaleX: 10.0,
    translateX: 0.0,
    scaleY: 50.0,
    translateY: 0.0,
    height: 200.0,
  );

  final ChartStyleSheet sheet = ChartStyleSheet(0, <ChartStyleEntry>[
    ChartStyleEntry(
      gridDomainStyleKey,
      ChartPaintStyle(
        strokeColor: const Color(0xFF666666),
        strokeWidth: 0.5,
        strokeCap: StrokeCap.butt,
        strokeJoin: StrokeJoin.miter,
        dashPattern: Float64List(0),
        fillColor: const Color(0x00000000),
      ),
    ),
    ChartStyleEntry(
      gridMeasureStyleKey,
      ChartPaintStyle(
        strokeColor: const Color(0xFF999999),
        strokeWidth: 0.5,
        strokeCap: StrokeCap.butt,
        strokeJoin: StrokeJoin.miter,
        dashPattern: Float64List(0),
        fillColor: const Color(0x00000000),
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

  group('Chart grid layer', () {
    // Confirms incoming arrays are defensively copied before painting.
    test('copies input arrays and paints without modifying them', () {
      final Float32List domainLines = Float32List.fromList(<double>[0.0, 1.0]);
      final Float32List measureLines = Float32List.fromList(<double>[
        0.0,
        1.0,
        2.0,
      ]);

      final ChartGridLayer layer = ChartGridLayer(
        const ChartLayerKey('grid.layer'),
        domainLines: domainLines,
        measureLines: measureLines,
        domainStyleKey: gridDomainStyleKey,
        measureStyleKey: gridMeasureStyleKey,
      );

      domainLines[0] = 42.0;
      measureLines[2] = 99.0;

      expect(layer.domainPositions[0], 0.0);
      expect(layer.measurePositions[2], 2.0);

      final PictureRecorder recorder = PictureRecorder();
      final ChartRenderContext context = buildContext(recorder);
      layer.paint(context);
      recorder.endRecording().dispose();
    });
  });
}
