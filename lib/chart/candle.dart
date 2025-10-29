import 'dart:ui';

import 'package:pulse/chart/foundation.dart';
import 'package:pulse/chart/node.dart';

class ChartCandleLayer extends ChartLayer {
  ChartCandleLayer(super.key, List<ChartCandleNode> nodes)
    : nodes = List<ChartCandleNode>.unmodifiable(nodes);

  final List<ChartCandleNode> nodes;

  @override
  void paint(ChartRenderContext context) {
    final Canvas canvas = context.canvas;
    final ChartTransform transform = context.transform;
    for (int i = 0; i < nodes.length; i += 1) {
      final ChartCandleNode node = nodes[i];
      final ChartPaintBundle bundle = context.paintCache.resolve(
        context.styleSheet,
        node.styleKey,
      );
      final Path bodyPath = node.bodyPathForTransform(transform);
      bundle.strokePath(canvas, node.wickPathForTransform(transform));
      canvas.drawPath(bodyPath, bundle.fill);
      bundle.strokePath(canvas, bodyPath);
    }
  }
}
