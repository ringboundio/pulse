import 'dart:ui';

import 'package:pulse/chart/foundation.dart';
import 'package:pulse/chart/node.dart';

class ChartAreaLayer extends ChartLayer {
  ChartAreaLayer(super.key, List<ChartAreaNode> nodes)
    : nodes = List<ChartAreaNode>.unmodifiable(nodes);

  final List<ChartAreaNode> nodes;

  @override
  void paint(ChartRenderContext context) {
    final Canvas canvas = context.canvas;
    final Path fillPath = context.scratchSpace.primaryPath;
    final Path strokePath = context.scratchSpace.secondaryPath;
    for (int i = 0; i < nodes.length; i += 1) {
      final ChartAreaNode node = nodes[i];
      node.writeFill(fillPath, context.transform);
      node.upper.writeToPath(strokePath, context.transform);
      final ChartPaintBundle bundle = context.paintCache.resolve(
        context.styleSheet,
        node.styleKey,
      );
      canvas.drawPath(fillPath, bundle.fill);
      canvas.drawPath(strokePath, bundle.stroke);
    }
  }
}
