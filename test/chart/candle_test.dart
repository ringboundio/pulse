import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:pulse/chart/candle.dart';
import 'package:pulse/chart/foundation.dart';
import 'package:pulse/chart/node.dart';
import 'package:pulse/chart/style.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const ChartStyleKey candleStyleKey = ChartStyleKey('test.candle');
  const ChartTransform kTransform = ChartTransform(
    scaleX: 10.0,
    translateX: 0.0,
    scaleY: 50.0,
    translateY: 0.0,
    height: 200.0,
  );

  final ChartStyleSheet sheet = ChartStyleSheet(0, <ChartStyleEntry>[
    ChartStyleEntry(
      candleStyleKey,
      ChartPaintStyle(
        strokeColor: const Color(0xFF336699),
        strokeWidth: 1.0,
        strokeCap: StrokeCap.butt,
        strokeJoin: StrokeJoin.miter,
        dashPattern: Float64List(0),
        fillColor: const Color(0x55336699),
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

  group('Chart candle layer', () {
    // Validates body and wick geometry map to expected pixel bounds.
    test('body and wick paths reflect geometry', () {
      final ChartCandleGeometry geometry = ChartCandleGeometry(
        Float32List.fromList(<double>[
          1.0, // domain
          2.0, // open
          3.0, // high
          1.0, // low
          1.5, // close
          0.25, // half width
        ]),
      );
      final ChartCandleNode node = ChartCandleNode(
        const ChartNodeKey('candle.node'),
        candleStyleKey,
        geometry,
      );
      final ChartCandleLayer layer = ChartCandleLayer(
        const ChartLayerKey('candle.layer'),
        <ChartCandleNode>[node],
      );

      final Rect bodyBounds = node.bodyPathForTransform(kTransform).getBounds();
      expect(bodyBounds.left, closeTo(7.5, 1e-6));
      expect(bodyBounds.right, closeTo(12.5, 1e-6));
      expect(bodyBounds.top, closeTo(100.0, 1e-6));
      expect(bodyBounds.bottom, closeTo(125.0, 1e-6));

      final Rect wickBounds = node.wickPathForTransform(kTransform).getBounds();
      expect(wickBounds.left, closeTo(10.0, 1e-6));
      expect(wickBounds.right, closeTo(10.0, 1e-6));
      expect(wickBounds.top, closeTo(50.0, 1e-6));
      expect(wickBounds.bottom, closeTo(150.0, 1e-6));

      final PictureRecorder recorder = PictureRecorder();
      final ChartRenderContext context = buildContext(recorder);
      layer.paint(context);
      recorder.endRecording().dispose();
    });
  });
}
