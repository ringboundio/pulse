import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:pulse/chart/bar.dart';
import 'package:pulse/chart/data.dart';
import 'package:pulse/chart/foundation.dart';
import 'package:pulse/chart/line.dart';
import 'package:pulse/chart/node.dart';
import 'package:pulse/chart/painter.dart';
import 'package:pulse/chart/style.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Confirms renderer can draw a simple line chart into a picture recorder.
  test('ChartRenderer renders simple line scene to picture', () {
    final ChartStyleKey styleKey = ChartStyleKey('line');
    final ChartStyleKey barStyleKey = ChartStyleKey('bar');
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
    final ChartBarNode barNode = ChartBarNode(
      ChartNodeKey('bar-node'),
      barStyleKey,
      ChartBarGeometry(Float32List.fromList(<double>[0.0, 0.0, 3.0, 0.4])),
    );
    final ChartScene scene = ChartScene(
      ChartSpace(ChartDoubleRange(0.0, 10.0), ChartDoubleRange(0.0, 5.0), 2.0),
      <ChartLayer>[
        ChartBarLayer(ChartLayerKey('bar-layer'), <ChartBarNode>[barNode]),
        ChartLineLayer(ChartLayerKey('line-layer'), <ChartLineNode>[node]),
      ],
    );
    final ChartPaintStyle style = ChartPaintStyle(
      strokeColor: const Color(0xFF00AACC),
      strokeWidth: 2.0,
      strokeCap: StrokeCap.round,
      strokeJoin: StrokeJoin.round,
      dashPattern: Float64List(0),
      fillColor: const Color(0x00000000),
    );
    final ChartPaintStyle barStyle = ChartPaintStyle(
      strokeColor: const Color(0xFF0085CC),
      strokeWidth: 1.0,
      strokeCap: StrokeCap.butt,
      strokeJoin: StrokeJoin.miter,
      dashPattern: Float64List(0),
      fillColor: const Color(0x550085CC),
    );
    final ChartSceneGraph graph = ChartSceneGraph(
      scene,
      ChartStyleSheet(0, <ChartStyleEntry>[
        ChartStyleEntry(styleKey, style),
        ChartStyleEntry(barStyleKey, barStyle),
      ]),
    );

    final ChartRenderer renderer = ChartRenderer();
    final ChartPaintCache cache = ChartPaintCache();
    final ChartScratchSpace scratchSpace = ChartScratchSpace();

    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    renderer.render(
      canvas: canvas,
      size: const Size(200.0, 100.0),
      graph: graph,
      cache: cache,
      scratchSpace: scratchSpace,
    );
    final Picture picture = recorder.endRecording();

    expect(picture, isNotNull);
    picture.dispose();
  });
}
