import 'dart:ui';

import 'package:pulse/chart/foundation.dart';
import 'package:pulse/chart/node.dart';

class ChartLineLayer extends ChartLayer {
  ChartLineLayer(super.key, List<ChartLineNode> nodes)
    : nodes = List<ChartLineNode>.unmodifiable(nodes);

  final List<ChartLineNode> nodes;

  @override
  void paint(ChartRenderContext context) {
    final Canvas canvas = context.canvas;
    final ChartTransform transform = context.transform;
    for (int i = 0; i < nodes.length; i += 1) {
      final ChartLineNode node = nodes[i];
      final ChartPaintBundle bundle = context.paintCache.resolve(
        context.styleSheet,
        node.styleKey,
      );
      bundle.strokePath(
        canvas,
        node.geometry.dashedPathForTransform(transform, bundle.dashPattern),
      );
    }
  }
}
