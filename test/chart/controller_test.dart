import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:pulse/chart/controller.dart';
import 'package:pulse/chart/data.dart';
import 'package:pulse/chart/foundation.dart';
import 'package:pulse/chart/line.dart';
import 'package:pulse/chart/node.dart';
import 'package:pulse/chart/style.dart';

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
      strokeColor: const Color(0xFF3567F6),
      strokeWidth: 2.0,
      strokeCap: StrokeCap.round,
      strokeJoin: StrokeJoin.round,
      dashPattern: Float64List(0),
      fillColor: const Color(0x00000000),
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
      key: styleKey,
      style: ChartPaintStyle(
        strokeColor: const Color(0xFFF6455A),
        strokeWidth: 3.0,
        strokeCap: StrokeCap.round,
        strokeJoin: StrokeJoin.round,
        dashPattern: Float64List(0),
        fillColor: const Color(0x00000000),
      ),
    );

    expect(controller.revision, 1);
    expect(notifications, 1);
  });
}
